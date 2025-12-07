# ServiceConnect – SAP BTP / CAP Project Documentation

## Descripción General
- ServiceConnect es una aplicación desarrollada en SAP CAP (Cloud Application Programming) que expone servicios OData V4 para la gestión de profesionales, oficios y solicitudes de clientes.
- Backend listo para ejecución local con SQLite y migración a SAP HANA Cloud en SAP BTP.
- Integración prevista con: Fiori Elements, SAPUI5, apps móviles y frontends React/Next.js.

## Tecnologías Utilizadas
- SAP CAP (`@sap/cds`)
- Node.js 18+
- OData V4
- SQLite (desarrollo)
- HANA Cloud (producción-ready)
- Express
- Arquitectura modular CAP

## Estructura del Proyecto
```
db/
  └── schema.cds     → Modelo de datos (entidades, asociaciones)
srv/
  └── service.cds    → Servicios OData expuestos
.cdsrc.json          → Configuración CAP (DB, opciones)
package.json         → Scripts, dependencias
```

## Comandos Principales

| Acción                     | Comando         |
|----------------------------|-----------------|
| Instalar dependencias      | `npm install`   |
| Desplegar modelo a SQLite  | `npm run deploy`|
| Iniciar servidor CAP       | `npm start`     |

## Endpoints OData
- Base URL: `http://localhost:4004/odata/v4/service-connect`
- Endpoints principales:
  - `/Professional`
  - `/Trade`
  - `/ServiceCategory`
  - `/ServiceOffering`
  - `/Client`
  - `/ClientRequest`
  - `/Assignment`
  - `/Review`
- Acciones:
  - `POST /assignProfessional`
  - `POST /autoAssignNearest`
- Metadata OData: `/odata/v4/service-connect/$metadata`

## UI Frontends
- Fiori Elements Preview con anotaciones UI en `srv/service.cds`.
- SAPUI5 moderna (Work Zone style) servida en: `http://localhost:4004/ui/profesional-modern/`.
  - Tema `sap_horizon_dark` y CSS custom en `app/profesional-modern/webapp/css/custom.css`.
  - Cards de estadísticas y acciones rápidas.
  - Tabla con íconos y badges de disponibilidad.

## CRUD de Profesionales (UI + OData)
- Alta (POST) desde UI:
  - Formulario en `app/profesional-modern/webapp/view/ProfessionalRegister.view.xml:1`.
  - Lógica de creación en `app/profesional-modern/webapp/controller/ProfessionalRegister.controller.js:4`.
  - Al registrar, se crea automáticamente:
    - `MessageThread` inicial vinculado al profesional (`ProfessionalRegister.controller.js:6`–`7`).
    - `ServiceOffering` por defecto para demo (`ProfessionalRegister.controller.js:8`).
- Edición (PATCH) desde UI:
  - Vista `app/profesional-modern/webapp/view/ProfessionalEdit.view.xml:11`.
  - Guardado con `submitBatch()` en `app/profesional-modern/webapp/controller/ProfessionalEdit.controller.js:5`–`6`.
- Eliminación (DELETE) desde UI:
  - Botón en `app/profesional-modern/webapp/view/ProfessionalDetail.view.xml:9`.
  - Acción `context.delete()` en `app/profesional-modern/webapp/controller/ProfessionalDetail.controller.js:7`.
- Navegación FCL:
  - Master → `navTo('Route_Detail', { professionalId })` (`app/profesional-modern/webapp/controller/Master.controller.js:13`).
  - Detalle → `navTo('Route_Edit', ...)` y `navTo('Route_Chat', ...)` (`ProfessionalDetail.controller.js:5`–`6`).
  - Registro → `navTo('Route_Register')` (`Master.controller.js:14`).

### Ejemplos OData (API)
- Crear profesional:
```
POST /odata/v4/service-connect/Professional
Content-Type: application/json
{
  "ID": "<uuid>",
  "fullName": "Juan Pérez",
  "professionType": "plumber",
  "trade_ID_ID": "<uuid-trade>",
  "registrationNumber": "MAT-12345",
  "email": "juan.perez@example.com",
  "phone": "+54 11 5555-5555",
  "location": "CABA",
  "rating": 4.5,
  "availability": true,
  "createdAt": "2025-01-01T10:00:00Z",
  "updatedAt": "2025-01-01T10:00:00Z"
}
```
- Editar profesional:
```
PATCH /odata/v4/service-connect/Professional('<ID>')
Content-Type: application/json
{ "availability": false, "rating": 4.8 }
```
- Eliminar profesional:
```
DELETE /odata/v4/service-connect/Professional('<ID>')
```

## FlexibleColumnLayout y Routing
- `manifest.json` define rutas y targets:
  - `Route_Master` → `view/Master.view.xml` (lista en columna 1).
  - `Route_Detail` → `view/ProfessionalDetail.view.xml` (detalle en columna 2).
  - `Route_Edit` → `view/ProfessionalEdit.view.xml` (formulario en columna 3).
  - `Route_Chat` → `view/Chat.view.xml` (chat en columna 3).
  - `Route_Register` → `view/ProfessionalRegister.view.xml` (alta en columna 3).
- Navegación:
  - `navTo("Route_Detail", { professionalId: ID })` desde la tabla.
  - `navTo("Route_Edit", { professionalId: ID })` desde el botón “Editar”.
  - `navTo("Route_Chat", { threadId })` desde “Enviar mensaje”.

## Vistas y Controladores
- `view/App.view.xml` → `sap.f.FlexibleColumnLayout`.
- `view/Master.view.xml` + `controller/Master.controller.js`:
  - Búsqueda, filtros de rating y disponibilidad, orden por rating.
  - KPIs: total y promedio de `rating`.
- `view/ProfessionalDetail.view.xml` + `controller/ProfessionalDetail.controller.js`:
  - Card con datos del profesional.
  - Lista de `ServiceOffering` filtrada por profesional.
  - Botones “Editar” y “Enviar mensaje”.
- `view/ProfessionalEdit.view.xml` + `controller/ProfessionalEdit.controller.js`:
  - Form responsive con `StepInput` y `Select` para disponibilidad.
  - Guarda con `submitBatch()` y retorna al detalle.
- `view/Chat.view.xml` + `controller/Chat.controller.js`:
  - Lista vertical, burbujas: profesional derecha (azul), cliente izquierda (gris).
  - Envío: `POST /odata/v4/service-connect/Message` y recarga de mensajes.

## CSS Personalizado
- Archivo: `app/profesional-modern/webapp/css/custom.css`.
- Variables, tema oscuro y estilos de burbujas.

## Cómo abrir
- UI moderna: `http://localhost:4004/ui/profesional-modern/`.
- Servicio: `http://localhost:4004/odata/v4/service-connect/`.

## Modelo de Datos (CDS)
- <span style="color:#0b5394">Professional</span>
  - Datos personales
  - Relación: `trade_ID → Trade`
- <span style="color:#0b5394">Trade</span>
  - Categorías de oficios (ej: Electricista, Plomero, Técnico)
- <span style="color:#0b5394">Client</span>
  - Información de clientes registrados
- <span style="color:#0b5394">ClientRequest</span>
  - Solicitudes de servicio
  - Relación: `client_ID → Client`
- <span style="color:#0b5394">ServiceOffering / ServiceCategory</span>
  - Servicios que brinda cada profesional
  - Categorías agrupadas
- <span style="color:#0b5394">Assignment</span>
  - Asignación de profesional a un trabajo
- <span style="color:#0b5394">Review</span>
  - Calificaciones posteriores al servicio

## Servicios OData (CAP)
- Archivo: `srv/service.cds`
- Importa el modelo desde `db/schema.cds`
- Expone entidades con CRUD completo
- Preparado para agregar lógica con handlers en `srv/*.js` si fuera necesario

## Configuración
- Archivo: `.cdsrc.json`
```json
{
  "requires": {
    "db": {
      "kind": "sqlite",
      "credentials": {
        "url": "db/sqlite.db"
      }
    }
  }
}
```

## Historial de Cambios
- Inicialización del proyecto CAP
- Configuración de entorno y scripts NPM
- Creación del modelo base (Profesionales & Oficios)
- Agregadas entidades: Client, ClientRequest, Assignment, Review
- Actualización de asociaciones (`trade_ID` y `client_ID`)
- Deploy inicial a SQLite
- Servidor CAP disponible en: `http://localhost:4004/`

## Funcionalidades añadidas (Plan PRO)

### 1. Calificaciones (Reviews + rating promedio)
- Al crear una `Review`, el backend recalcula el promedio y actualiza `Professional.rating` automáticamente.
- Implementación: `srv/service.js:26-39`.
```
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
```

### 2. Notificación por email al validar un profesional
- Campo nuevo en el modelo: `Professional.isVerified` (`db/schema.cds:13`).
- Cuando `isVerified` cambia a `true`, se envía email al profesional y se emite evento interno.
- Implementación: `srv/service.js:41-53`.
```
srv.after('UPDATE', 'Professional', async (data, req) => {
  if (data.isVerified !== true) return
  const tx = cds.transaction(req)
  const row = await tx.read(Professional).where({ ID: data.ID }).limit(1)
  if (row && row.email) {
    await sendMail(row.email, 'Tu perfil fue verificado', `Hola ${row.fullName}, tu perfil profesional ya está activo.`)
  }
  srv.emit('professionalValidated', { id: data.ID })
})
```

### 3. Notificación por email al crear una solicitud (ClientRequest)
- Al crear `ClientRequest`, se busca el mejor profesional disponible para esa categoría y se envía notificación.
- Implementación: `srv/service.js:58-71`.
```
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
```

### 4. Notificaciones internas (CAP Events)
- Emite y maneja eventos dentro del servicio, útil para integraciones y auditoría.
- Implementación: `srv/service.js:51-57`.
```
srv.emit('professionalValidated', { id: data.ID })
srv.on('professionalValidated', async (msg) => { return { ok: true, id: msg.id } })
```

### 5. Push notifications (opciones)
- CAP + WebSocket interno para apps web/SAPUI5.
- SAP Mobile Services para apps móviles SAP.
- Alternativas: notificación in-app, banners, toasts, WebPush.

### SMTP (configuración)
- Variables de entorno requeridas: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`.
- Si no se configuran, el envío de email se omite sin error.

### 6. Geolocalización y asignación por cercanía
- Nuevos campos en el modelo:
  - `Professional.latitude`, `Professional.longitude` (`db/schema.cds:12-13`).
  - `ClientRequest.latitude`, `ClientRequest.longitude` (`db/schema.cds:41-42`).
- Datos de ejemplo actualizados en CSV:
  - `db/data/serviceconnect-Professional.csv:1-3` con coordenadas de CABA.
  - `db/data/serviceconnect-ClientRequest.csv:1-3` con coordenadas de CABA y La Plata.
- Acción OData `autoAssignNearest` para asignar el profesional más cercano por categoría y disponibilidad:
  - Definición en `srv/service.cds:18-21`.
  - Handler Haversine en `srv/service.js:57-105`.
- Ejemplo de invocación:
```
POST /odata/v4/service-connect/autoAssignNearest
Content-Type: application/json
{
  "clientRequest_ID": "99999999-9999-9999-9999-999999999999",
  "maxRadiusKm": 20
}
```

### 7. Fiori Preview – UI como app
- Anotaciones UI agregadas para una experiencia tipo frontend en Fiori Preview:
  - `@UI.LineItem` para columnas por defecto (`srv/service.cds:24-30`, `srv/service.cds:51-57`, `srv/service.cds:89-94`).
  - `@UI.HeaderInfo` para títulos y descripciones de páginas de objeto (`srv/service.cds:33-37`, `srv/service.cds:64-68`, `srv/service.cds:97-101`).
  - `@UI.SelectionFields` para filtros en la barra superior (`srv/service.cds:38`, `srv/service.cds:69`, `srv/service.cds:102`).
  - `@UI.Facets` y `@UI.FieldGroup` para secciones y detalle (`srv/service.cds:39-49`, `srv/service.cds:71-86`, `srv/service.cds:103-114`).
  - `@UI.PresentationVariant` para ordenar `Professional` por `rating` desc (`srv/service.cds:58-61`).
- Rutas de preview:
  - Profesionales: `http://localhost:4004/$fiori-preview/ServiceConnectService/Professional`
  - Ofertas: `http://localhost:4004/$fiori-preview/ServiceConnectService/ServiceOffering`
  - Solicitudes: `http://localhost:4004/$fiori-preview/ServiceConnectService/ClientRequest`
