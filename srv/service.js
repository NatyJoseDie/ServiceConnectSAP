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
  const { Assignment, ClientRequest, Professional, Review, ServiceOffering, Tradesman, TradesmanSpecialization } = srv.entities
  const { Message, MessageThread, AvailabilitySlot, ServiceCategory, Trade } = srv.entities
  const { INSERT, SELECT, UPDATE } = cds.ql

  srv.on('assignProfessional', async (req) => {
    try {
      const { clientRequest_ID, professional_ID } = req.data

      const tx = cds.transaction(req)
      const exists = await tx.read(ClientRequest).where({ ID: clientRequest_ID }).limit(1)
      if (!exists || exists.length === 0) {
        console.log('>>> ClientRequest not found')
        return req.error(404, 'ClientRequest not found')
      }

      const myID = cds.utils.uuid()
      const now = new Date().toISOString()
      console.log('>>> Inserting Assignment with ID:', myID)

      await tx.run(
        INSERT.into(Assignment).entries({
          ID: myID,
          professional_ID: professional_ID,
          clientRequest_ID: clientRequest_ID,
          dateAssigned: now,
          status: 'accepted'
        })
      )

      await tx.update(ClientRequest, { ID: clientRequest_ID }).set({ status: 'assigned' })

      const newAssignment = await tx.run(SELECT.one.from(Assignment).where({ ID: myID }))
      const response = newAssignment || { ID: myID, professional_ID, clientRequest_ID, status: 'accepted', dateAssigned: now }
      response.message = "Asignación creada con éxito"
      return response
    } catch (e) { return req.error(500, e.message) }
  })

  srv.on('assignTradesman', async (req) => {
    try {
      const { clientRequest_ID, tradesman_ID } = req.data
      console.log('>>> assignTradesman called with:', { clientRequest_ID, tradesman_ID })

      const tx = cds.transaction(req)
      const exists = await tx.read(ClientRequest).where({ ID: clientRequest_ID }).limit(1)
      if (!exists || exists.length === 0) {
        console.log('>>> ClientRequest not found')
        return req.error(404, 'ClientRequest not found')
      }

      const myID = cds.utils.uuid()
      const now = new Date().toISOString()
      console.log('>>> Inserting Assignment (tradesman) with ID:', myID)

      await tx.run(
        INSERT.into(Assignment).entries({
          ID: myID,
          tradesman_ID: tradesman_ID,
          clientRequest_ID: clientRequest_ID,
          dateAssigned: now,
          status: 'accepted'
        })
      )

      await tx.update(ClientRequest, { ID: clientRequest_ID }).set({ status: 'assigned' })

      const newAssignment = await tx.run(SELECT.one.from(Assignment).where({ ID: myID }))
      const response = newAssignment || { ID: myID, tradesman_ID, clientRequest_ID, status: 'accepted', dateAssigned: now }
      response.message = "Asignación de oficio creada con éxito"
      return response
    } catch (e) { return req.error(500, e.message) }
  })

  srv.on('autoAssignNearest', async (req) => {
    const { clientRequest_ID, maxRadiusKm } = req.data
    const radius = typeof maxRadiusKm === 'number' && maxRadiusKm > 0 ? maxRadiusKm : 50
    const tx = cds.transaction(req)

    const cr = await tx.read(ClientRequest).where({ ID: clientRequest_ID }).limit(1)
    if (!cr || (Array.isArray(cr) && cr.length === 0)) return req.error(404, 'ClientRequest not found')
    const reqRow = Array.isArray(cr) ? cr[0] : cr
    const { latitude: clat, longitude: clng, serviceCategory_ID: catFk, specialization_ID: specFk } = reqRow
    if (clat == null || clng == null) return req.error(400, 'ClientRequest missing lat/lng')

    let offeringsSel = SELECT.from(ServiceOffering).where({ category_ID: catFk, active: true })
    if (specFk) offeringsSel = offeringsSel.where({ specialization_ID: specFk })
    const offerings = await tx.run(offeringsSel)
    if (!offerings || offerings.length === 0) return req.error(404, 'No offerings for category')
    const ids = offerings.map(o => o.professional_ID).filter(Boolean)
    if (ids.length === 0) return req.error(404, 'No professionals for offerings')

    const profs = await tx.run(
      SELECT.from(Professional)
        .where({ ID: { in: ids }, availability: true })
    )
    if (!profs || profs.length === 0) return req.error(404, 'No available professionals')

    const candidates = []
    for (const p of profs) {
      if (p.latitude == null || p.longitude == null) continue
      const dist = haversineKm(Number(clat), Number(clng), Number(p.latitude), Number(p.longitude))
      candidates.push({ p, dist })
    }
    if (!candidates.length) return req.error(404, 'No professionals with coordinates')
    candidates.sort((a, b) => a.dist - b.dist)
    let best = candidates[0]

    const assignment = await tx.run(
      INSERT.into(Assignment).entries({
        ID: cds.utils.uuid(),
        professional_ID: best.p.ID,
        clientRequest_ID: clientRequest_ID,
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

  srv.on('findNearestProfessionals', async (req) => {
    const { lat, lng, specialization_ID, maxRadiusKm, limit } = req.data
    const radius = typeof maxRadiusKm === 'number' && maxRadiusKm > 0 ? maxRadiusKm : 50
    const lim = typeof limit === 'number' && limit > 0 ? limit : 10
    const tx = cds.transaction(req)

    let profsQ = SELECT.from(Professional).columns('*')
    profsQ = profsQ.where({ availability: true })
    const profs = await tx.run(profsQ)
    const results = []
    for (const p of profs) {
      if (p.latitude == null || p.longitude == null) continue
      const d = haversineKm(Number(lat), Number(lng), Number(p.latitude), Number(p.longitude))
      if (d > radius) continue
      if (specialization_ID) {
        const hasSpec = await tx.run(
          SELECT.from('serviceconnect.ProfessionalSpecialization').where({ professional_ID: p.ID, specialization_ID: specialization_ID }).limit(1)
        )
        if (!hasSpec || hasSpec.length === 0) continue
      }
      let tradeName = ''
      if (p.trade_ID) {
        const t = await tx.read(Trade).where({ ID: p.trade_ID }).limit(1)
        tradeName = Array.isArray(t) && t.length > 0 ? t[0].name : ''
      }
      results.push({
        professional_ID: p.ID,
        fullName: p.fullName,
        tradeName,
        latitude: p.latitude,
        longitude: p.longitude,
        distanceKm: Number(d.toFixed(2)),
        rating: p.rating
      })
    }
    results.sort((a, b) => a.distanceKm - b.distanceKm)
    return results.slice(0, lim)
  })

  srv.on('findNearestTradesmen', async (req) => {
    const { lat, lng, specialization_ID, maxRadiusKm, limit } = req.data
    const radius = typeof maxRadiusKm === 'number' && maxRadiusKm > 0 ? maxRadiusKm : 50
    const lim = typeof limit === 'number' && limit > 0 ? limit : 10
    const tx = cds.transaction(req)

    let tradesQ = SELECT.from(Tradesman).columns('*')
    tradesQ = tradesQ.where({ availability: true })
    const trades = await tx.run(tradesQ)
    const results = []
    for (const t of trades) {
      if (t.latitude == null || t.longitude == null) continue
      const d = haversineKm(Number(lat), Number(lng), Number(t.latitude), Number(t.longitude))
      if (d > radius) continue
      if (specialization_ID) {
        const hasSpec = await tx.run(
          SELECT.from('serviceconnect.TradesmanSpecialization').where({ tradesman_ID: t.ID, specialization_ID: specialization_ID }).limit(1)
        )
        if (!hasSpec || hasSpec.length === 0) continue
      }
      let tradeName = ''
      if (t.trade_ID) {
        const tr = await tx.read(Trade).where({ ID: t.trade_ID }).limit(1)
        tradeName = Array.isArray(tr) && tr.length > 0 ? tr[0].name : ''
      }
      results.push({
        tradesman_ID: t.ID,
        fullName: t.fullName,
        tradeName,
        latitude: t.latitude,
        longitude: t.longitude,
        distanceKm: Number(d.toFixed(2)),
        rating: t.rating
      })
    }
    results.sort((a, b) => a.distanceKm - b.distanceKm)
    return results.slice(0, lim)
  })

  srv.before('CREATE', 'Message', async (req) => {
    const { content } = req.data
    if (!content || String(content).trim().length === 0) return req.error(400, 'Contenido del mensaje requerido')
  })
  srv.after('CREATE', 'Message', async (data, req) => {
    if (!data.createdAt) {
      const tx = cds.transaction(req)
      await tx.update(Message, { ID: data.ID }).set({ createdAt: new Date().toISOString(), isRead: false })
    }
  })

  srv.on('markMessageRead', async (req) => {
    const { message_ID } = req.data
    const tx = cds.transaction(req)
    const updated = await tx.update(Message, { ID: message_ID }).set({ isRead: true })
    return !!updated
  })

  srv.on('metricsByCategory', async (req) => {
    const tx = cds.transaction(req)
    const cats = await tx.run(SELECT.from(ServiceCategory))
    const out = []
    for (const c of cats) {
      const offs = await tx.run(SELECT.from(ServiceOffering).where({ category_ID: c.ID }))
      const profIds = [...new Set(offs.map(o => o.professional_ID).filter(Boolean))]
      let ratings = []
      if (profIds.length) {
        const profs = await tx.run(SELECT.from(Professional).columns('rating').where({ ID: { in: profIds } }))
        ratings = profs.map(p => Number(p.rating || 0)).filter(n => !Number.isNaN(n) && n > 0)
      }
      const avg = ratings.length ? (ratings.reduce((a, b) => a + b, 0) / ratings.length) : 0
      out.push({ category_ID: c.ID, count: offs.length, avgRating: Number(avg.toFixed(1)) })
    }
    return out
  })

  srv.on('metricsByLocation', async (req) => {
    const tx = cds.transaction(req)
    const rows = await tx.run(SELECT.from(ClientRequest).columns('location'))
    const map = new Map()
    for (const r of rows) {
      const k = r.location || 'N/D'
      map.set(k, (map.get(k) || 0) + 1)
    }
    return Array.from(map.entries()).map(([location, count]) => ({ location, count }))
  })

  srv.on('metricsByRating', async (req) => {
    const tx = cds.transaction(req)
    const rows = await tx.run(SELECT.from(Review).columns('rating'))
    const map = new Map()
    for (const r of rows) {
      const k = Number(r.rating || 0).toFixed(1)
      map.set(k, (map.get(k) || 0) + 1)
    }
    return Array.from(map.entries()).map(([rating, count]) => ({ rating: Number(rating), count }))
  })

  srv.before('CREATE', 'Review', async (req) => {
    const { rating, comment } = req.data
    const r = Number(rating)
    if (Number.isNaN(r) || r < 1 || r > 5) return req.error(400, 'Rating debe ser 1..5')
    if (!comment || String(comment).trim().length === 0) return req.error(400, 'Comentario requerido')
  })

  srv.before('UPDATE', 'Assignment', async (req) => {
    const { status, ID } = req.data
    if (status !== 'completed') return
    const tx = cds.transaction(req)
    const row = await tx.read(Assignment).where({ ID }).limit(1)
    if (!row || (Array.isArray(row) && row.length === 0)) return req.error(404, 'Assignment not found')
    const a = Array.isArray(row) ? row[0] : row
    const revs = await tx.run(SELECT.from(Review).where({ professional_ID: a.professional_ID, clientRequest_ID: a.clientRequest_ID }))
    if (!revs || revs.length === 0) return req.error(400, 'Debe ingresar una valoración con comentario antes de completar')
  })

  srv.after('CREATE', 'Review', async (data, req) => {
    const tx = cds.transaction(req)
    const pid = data.professional_ID || (data.professional && data.professional.ID)
    if (!pid) return
    const rows = await tx.run(SELECT.from(Review).columns('rating').where({ professional_ID: pid }))
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
    const cat = data.serviceCategory_ID || (data.serviceCategory && data.serviceCategory.ID)
    const spec = data.specialization_ID || (data.specialization && data.specialization.ID)
    if (!cat) return
    let q = SELECT.from(ServiceOffering).where({ category_ID: cat, active: true })
    if (spec) q = q.where({ specialization_ID: spec })
    const offerings = await tx.run(q)
    if (!offerings || offerings.length === 0) return
    const ids = offerings.map(o => o.professional_ID).filter(Boolean)
    if (ids.length === 0) return
    const profs = await tx.run(SELECT.from(Professional).where({ ID: { in: ids }, availability: true }).orderBy({ ref: ['rating'], sort: 'DESC' }))
    const prof = Array.isArray(profs) ? profs[0] : profs
    if (prof && prof.email) {
      const text = `Hola ${prof.fullName}, un cliente desea contactarte. Descripción: ${data.description || ''}. Ubicación: ${data.location || ''}.`
      await sendMail(prof.email, 'Nueva solicitud recibida', text)
    }
  })
}
