const cds = require('@sap/cds')
const nodemailer = require('nodemailer')

let transporter
function mailer() {
  if (transporter) return transporter
  const host = process.env.SMTP_HOST
  const port = process.env.SMTP_PORT ? Number(process.env.SMTP_PORT) : undefined
  const user = process.env.SMTP_USER
  const pass = process.env.SMTP_PASS
  if (!host || !user || !pass) return undefined
  transporter = nodemailer.createTransport({ host, port, auth: { user, pass } })
  return transporter
}
async function sendMail(to, subject, text) {
  const t = mailer()
  if (!t) return
  const from = process.env.SMTP_FROM || 'no-reply@serviceconnect.local'
  await t.sendMail({ from, to, subject, text })
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (n) => (n * Math.PI) / 180
  const R = 6371
  const dLat = toRad(lat2 - lat1)
  const dLon = toRad(lon2 - lon1)
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}

module.exports = async (srv) => {
  await cds.connect.to('db')
  const { Assignment, ClientRequest, Professional, Review, ServiceOffering } = srv.entities
  const { INSERT, SELECT, UPDATE } = cds.ql

  srv.on('assignProfessional', async (req) => {
    const { clientRequest_ID, professional_ID } = req.data
    const tx = cds.transaction(req)
    const exists = await tx.read(ClientRequest).where({ ID: clientRequest_ID }).limit(1)
    if (!exists || exists.length === 0) return req.error(404, 'ClientRequest not found')

    const assignment = await tx.run(
      INSERT.into(Assignment).entries({
        ID: cds.utils.uuid(),
        professional_ID_ID: professional_ID,
        clientRequest_ID_ID: clientRequest_ID,
        dateAssigned: new Date().toISOString(),
        status: 'accepted'
      })
    )

    await tx.update(ClientRequest, { ID: clientRequest_ID }).set({ status: 'assigned' })
    return assignment
  })

  srv.on('autoAssignNearest', async (req) => {
    const { clientRequest_ID, maxRadiusKm } = req.data
    const radius = typeof maxRadiusKm === 'number' && maxRadiusKm > 0 ? maxRadiusKm : 50
    const tx = cds.transaction(req)

    const cr = await tx.read(ClientRequest).where({ ID: clientRequest_ID }).limit(1)
    if (!cr || (Array.isArray(cr) && cr.length === 0)) return req.error(404, 'ClientRequest not found')
    const reqRow = Array.isArray(cr) ? cr[0] : cr
    const { latitude: clat, longitude: clng, serviceCategory_ID_ID: catFk } = reqRow
    if (clat == null || clng == null) return req.error(400, 'ClientRequest missing lat/lng')

    const offerings = await tx.run(SELECT.from(ServiceOffering).where({ category_ID_ID: catFk, active: true }))
    if (!offerings || offerings.length === 0) return req.error(404, 'No offerings for category')
    const ids = offerings.map(o => o.professional_ID_ID).filter(Boolean)
    if (ids.length === 0) return req.error(404, 'No professionals for offerings')

    const profs = await tx.run(
      SELECT.from(Professional)
        .where({ ID: { in: ids }, availability: true })
    )
    if (!profs || profs.length === 0) return req.error(404, 'No available professionals')

    let best = null
    for (const p of profs) {
      if (p.latitude == null || p.longitude == null) continue
      const dist = haversineKm(Number(clat), Number(clng), Number(p.latitude), Number(p.longitude))
      if (dist <= radius) {
        if (!best || dist < best.dist) best = { p, dist }
      }
    }
    if (!best) return req.error(404, 'No professionals within radius')

    const assignment = await tx.run(
      INSERT.into(Assignment).entries({
        ID: cds.utils.uuid(),
        professional_ID_ID: best.p.ID,
        clientRequest_ID_ID: clientRequest_ID,
        dateAssigned: new Date().toISOString(),
        status: 'accepted'
      })
    )
    await tx.update(ClientRequest, { ID: clientRequest_ID }).set({ status: 'assigned' })

    if (best.p.email) {
      const text = `Solicitud cercana asignada (≈ ${best.dist.toFixed(1)} km). Cliente: ${reqRow.clientName || ''}. Ubicación: ${reqRow.location || ''}.`
      await sendMail(best.p.email, 'Nueva solicitud cercana asignada', text)
    }
    return assignment
  })

  srv.after('CREATE', 'Review', async (data, req) => {
    const tx = cds.transaction(req)
    const pid = data.professional_ID_ID || (data.professional_ID && data.professional_ID.ID) || data.professional_ID
    if (!pid) return
    const rows = await tx.run(SELECT.from(Review).columns('rating').where({ professional_ID_ID: pid }))
    if (!rows || rows.length === 0) return
    const avg = rows.reduce((a, r) => a + Number(r.rating || 0), 0) / rows.length
    const rounded = Number(avg.toFixed(1))
    await tx.run(UPDATE(Professional).set({ rating: rounded }).where({ ID: pid }))
  })

  srv.after('UPDATE', 'Professional', async (data, req) => {
    if (data.isVerified !== true) return
    const tx = cds.transaction(req)
    const row = await tx.read(Professional).where({ ID: data.ID }).limit(1)
    if (row && row.email) {
      await sendMail(row.email, 'Tu perfil fue verificado', `Hola ${row.fullName}, tu perfil profesional ya está activo.`)
    }
    srv.emit('professionalValidated', { id: data.ID })
  })

  srv.on('professionalValidated', async (msg) => {
    return { ok: true, id: msg.id }
  })

  srv.after('CREATE', 'ClientRequest', async (data, req) => {
    const tx = cds.transaction(req)
    const cat = data.serviceCategory_ID_ID || (data.serviceCategory_ID && data.serviceCategory_ID.ID) || data.serviceCategory_ID
    if (!cat) return
    const offerings = await tx.run(SELECT.from(ServiceOffering).where({ category_ID_ID: cat, active: true }))
    if (!offerings || offerings.length === 0) return
    const ids = offerings.map(o => o.professional_ID_ID).filter(Boolean)
    if (ids.length === 0) return
    const profs = await tx.run(SELECT.from(Professional).where({ ID: { in: ids }, availability: true }).orderBy({ ref: ['rating'], sort: 'DESC' }))
    const prof = Array.isArray(profs) ? profs[0] : profs
    if (prof && prof.email) {
      const text = `Hola ${prof.fullName}, un cliente desea contactarte. Descripción: ${data.description || ''}. Ubicación: ${data.location || ''}.`
      await sendMail(prof.email, 'Nueva solicitud recibida', text)
    }
  })
}
