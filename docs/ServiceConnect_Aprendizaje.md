# ServiceConnect – Guía de Aprendizaje

## Qué es CAP y CDS
- CAP: marco de SAP para construir servicios empresariales con buenas prácticas.
- CDS: lenguaje de modelado (archivos `.cds`) para definir entidades, tipos y asociaciones.
- CAP compila CDS y expone servicios (OData/REST) con runtime Node.js.

## Flujo de trabajo
- Modelar datos en `db/schema.cds`.
- Definir servicio en `srv/service.cds` que proyecta entidades del modelo.
- Desplegar a base (`npm run deploy`) y ejecutar el servidor (`npm start`).

## Entender el modelo
- Namespace: `serviceconnect` (`db/schema.cds:1`).
- `Professional`:
  - Campos principales y `trade_ID` → `Trade` (`db/schema.cds:3-15`, `db/schema.cds:7`).
- `ServiceCategory` y `ServiceOffering`:
  - `ServiceOffering` asocia `Professional` y `ServiceCategory` (`db/schema.cds:24-31`).
- `ClientRequest`:
  - Datos del cliente + `client_ID` → `Client` (`db/schema.cds:34-44`, `db/schema.cds:38`).
- `Assignment` enlaza un `Professional` con un `ClientRequest` (`db/schema.cds:46-52`).
- `Review` referencia a `Professional` (`db/schema.cds:54-60`).
- `Client` y `Trade` son entidades base (`db/schema.cds:62-77`).

## Entender el servicio OData
- Importación del modelo: `using { serviceconnect } from '../db/schema';` (`srv/service.cds:1`).
- Servicio `ServiceConnectService` expone proyecciones (`srv/service.cds:4-11`).
- Ruta base del servicio: `/odata/v4/service-connect`.
- Acción `assignProfessional` (`srv/service.cds:13`) que:
  - Recibe `clientRequest_ID` y `professional_ID`.
  - Crea un `Assignment` y setea `ClientRequest.status` a `assigned`.
  - Handler en `srv/service.js:1`.

## Probando el servicio
- Ver metadata: `GET /odata/v4/service-connect/$metadata`.
- Listar colecciones: `GET /odata/v4/service-connect/Professional` (y demás).
- Crear un `Professional`:
```
POST /odata/v4/service-connect/Professional
Content-Type: application/json
{
  "ID": "e3b0c442-98fc-1c14-9afc-000000000001",
  "fullName": "Juan Pérez",
  "professionType": "plumber",
  "trade_ID_ID": "11111111-1111-1111-1111-111111111111",
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
- Nota: en asociaciones OData V4, el foreign key se expresa como `<assoc>_ID` al usar valores directos.
- Invocar acción:
```
POST /odata/v4/service-connect/assignProfessional
Content-Type: application/json
{
  "clientRequest_ID": "99999999-9999-9999-9999-999999999999",
  "professional_ID": "77777777-7777-7777-7777-777777777777"
}
```

## Configuración de entorno
- `.cdsrc.json` define base de datos y perfiles.
  - Dev: `kind: sqlite`, `credentials.url: db/sqlite.db` (`.cdsrc.json:2-9`).
- `package.json` scripts:
  - `start`: `cds run` (`package.json:7`).
  - `deploy`: `cds deploy --to sqlite:db/sqlite.db` (`package.json:9`).

## Buenas prácticas
- Usar `UUID` como claves primarias.
- Mantener timestamps (`createdAt`, `updatedAt`).
- Definir asociaciones en CDS en lugar de duplicar datos (ej. `client_ID` en vez de `clientEmail`).
- Separar entidades base (`Client`, `Trade`) de las transaccionales (`ClientRequest`, `Assignment`).

## Siguientes pasos sugeridos
- Defaults y generación automática de `ID` y timestamps en handlers.
- Datos de ejemplo (`db/data/*.csv`) para pruebas rápidas.
- Validaciones de dominio (rating 0–5, estados válidos).
- Autenticación y roles (`@requires`) en el servicio.
- Preparar perfil `production` con HANA Cloud y deploy en BTP.
  - Agregar `requires.db.kind: hana` y dependencias HANA.

## UI5 moderna sobre CAP (Work Zone style)
- App SAPUI5 servida desde CAP: `http://localhost:4004/ui/profesional-modern/`.
- Tema: `sap_horizon_dark` con CSS personalizado en `/app/profesional-modern/webapp/css/custom.css`.
- Layout: `sap.f.FlexibleColumnLayout` y `sap.f.GridContainer` para tarjetas y diseño responsive.
- Routing en `manifest.json`:
  - `Route_Master` → lista de profesionales (columna 1).
  - `Route_Detail` → detalle de profesional (columna 2).
  - `Route_Edit` → edición (columna 3).
  - `Route_Chat` → chat (columna 3) con parámetro `threadId`.
- Vistas y controladores principales:
  - `view/App.view.xml` → FCL.
  - `view/Master.view.xml` + `controller/Master.controller.js` → toolbar, filtros, cards de estadísticas y acciones rápidas.
  - `view/ProfessionalDetail.view.xml` + `controller/ProfessionalDetail.controller.js` → perfil y servicios.
  - `view/ProfessionalEdit.view.xml` + `controller/ProfessionalEdit.controller.js` → formulario editable con `submitBatch()`.
  - `view/Chat.view.xml` + `controller/Chat.controller.js` → chat tipo WhatsApp con burbujas.
- Inyección de CSS: `manifest.json → sap.ui5.resources.css: css/custom.css`.
- Buenas prácticas UI5:
  - Mantener bindings OData V4 en `manifest.json` con `serviceUrl: /odata/v4/service-connect/`.
  - Usar `ObjectStatus` y `ObjectNumber` para estados y KPIs.
  - Delegar navegación a `sap.f.routing.Router` para columnas FCL.

## Despliegue en SAP BTP (resumen)
- Opción rápida (Cloud Foundry, demo en SQLite):
  - `cf login`, `cf push` con `manifest.yml` iniciando `npm start`.
  - Sirve UI5 desde `srv/server.js` en `/ui/profesional-modern/`.
- Opción recomendada (Approuter + HANA Cloud):
  - `requires.db.kind: hana` y HDI container en `mta.yaml`.
  - Approuter con `xs-app.json`:
    - Rutas estáticas a `/app/profesional-modern/webapp`.
    - Proxy `/odata/v4/**` al backend CAP.
  - `mbt build` y `cf deploy` del `.mtar`.
  - Autenticación con XSUAA y roles en CAP según `@requires`.

## Plan PRO de funcionalidades

### 1. Calificaciones (Reviews + rating promedio)
- Al crear una `Review`, el servicio recalcula el promedio de `rating` del profesional y lo guarda.
- Código en `srv/service.js:26-39` (handler `after CREATE Review`).
- Ventaja: los frontends consumen el valor ya calculado sin lógica adicional.

### 2. Notificación por email al validar profesional
- Nuevo campo `Professional.isVerified` (`db/schema.cds:13`).
- Al pasar a `true`, se envía email al profesional y se emite un evento interno.
- Código en `srv/service.js:41-53`.

### 3. Notificación por email al crear `ClientRequest`
- Al crear una solicitud, busca el mejor profesional disponible para la categoría y envía notificación.
- Código en `srv/service.js:58-71`.

### 4. Notificaciones internas (CAP Events)
- Emisión y manejo de eventos para integraciones, auditoría y microservicios.
- Ejemplo: `professionalValidated` (`srv/service.js:51-57`).

### 5. Push notifications (opciones)
- CAP + WebSocket para apps web/ SAPUI5.
- SAP Mobile Services si se desarrolla una app móvil SAP.
- Alternativas para portfolio: in-app, banners, toasts, WebPush.

### SMTP y email
- Configurar `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM` como variables de entorno.
- Sin configuración, el envío se omite de forma segura.

### 6. Geolocalización y asignación por cercanía
- Extensión del modelo con lat/lng:
  - `Professional.latitude`, `Professional.longitude` (`db/schema.cds:12-13`).
  - `ClientRequest.latitude`, `ClientRequest.longitude` (`db/schema.cds:41-42`).
- CSVs de ejemplo actualizados:
  - `db/data/serviceconnect-Professional.csv:1-3` y `db/data/serviceconnect-ClientRequest.csv:1-3`.
- Acción OData `autoAssignNearest`:
  - Definida en `srv/service.cds:18-21`.
  - Handler con fórmula Haversine en `srv/service.js:57-105`.
- Flujo: desde una `ClientRequest` con categoría y coordenadas, encuentra profesionales disponibles con `ServiceOffering` en esa categoría, mide distancia y asigna el más cercano dentro del radio.

### 7. Fiori Preview avanzado (UI annotations)
- Se agregaron anotaciones para que el preview se vea como una app terminada:
  - `@UI.LineItem` para columnas por defecto (`srv/service.cds:24-30`, `srv/service.cds:51-57`, `srv/service.cds:89-94`).
  - `@UI.HeaderInfo` para cabeceras de objeto (`srv/service.cds:33-37`, `srv/service.cds:64-68`, `srv/service.cds:97-101`).
  - `@UI.SelectionFields` para filtros (`srv/service.cds:38`, `srv/service.cds:69`, `srv/service.cds:102`).
  - `@UI.Facets` + `@UI.FieldGroup` para secciones de detalle (`srv/service.cds:39-49`, `srv/service.cds:71-86`, `srv/service.cds:103-114`).
  - `@UI.PresentationVariant` para ordenar `Professional` por `rating` desc (`srv/service.cds:58-61`).
- Rutas de preview:
  - `http://localhost:4004/$fiori-preview/ServiceConnectService/Professional`
  - `http://localhost:4004/$fiori-preview/ServiceConnectService/ServiceOffering`
  - `http://localhost:4004/$fiori-preview/ServiceConnectService/ClientRequest`

## Referencias rápidas
- Servicio: `srv/service.cds:3-11`.
- Entidades clave: `db/schema.cds:34-44` (`ClientRequest`), `db/schema.cds:62-77` (`Client`, `Trade`).
- Comandos: `npm run deploy`, `npm start`.

## Guía rápida de pruebas

- Base: `http://localhost:4004/odata/v4/service-connect`

- Crear Review y actualizar rating:
```
POST /odata/v4/service-connect/Review
Content-Type: application/json
{
  "ID": "15151515-1515-1515-1515-151515151515",
  "professional_ID_ID": "77777777-7777-7777-7777-777777777777",
  "rating": 4.0,
  "comment": "Buen servicio",
  "createdAt": "2025-01-01T10:00:00Z"
}
```
Luego consulta:
```
GET /odata/v4/service-connect/Professional('77777777-7777-7777-7777-777777777777')
```

- Verificar profesional (dispara email si SMTP configurado):
```
PATCH /odata/v4/service-connect/Professional('77777777-7777-7777-7777-777777777777')
Content-Type: application/json
{
  "isVerified": true
}
```

- Crear solicitud (envía email al mejor profesional disponible de la categoría):
```
POST /odata/v4/service-connect/ClientRequest
Content-Type: application/json
{
  "ID": "23232323-2323-2323-2323-232323232323",
  "client_ID_ID": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "serviceCategory_ID_ID": "44444444-4444-4444-4444-444444444444",
  "description": "Pérdida de agua en cocina",
  "location": "CABA",
  "status": "pending",
  "createdAt": "2025-01-02T10:00:00Z"
}
```

- Acción de asignación (opcional, si preferís manual):
```
POST /odata/v4/service-connect/assignProfessional
Content-Type: application/json
{
  "clientRequest_ID": "99999999-9999-9999-9999-999999999999",
  "professional_ID": "77777777-7777-7777-7777-777777777777"
}
```

## Errores comunes y soluciones

- Error 400 "Deserialization Error: Expected property name or '}'":
  - El body JSON está mal formateado (comas finales, comillas simples, BOM, o tooling que inyecta texto). Usa Postman o `curl` y asegúrate de `Content-Type: application/json` y comillas dobles.
- Asociaciones en OData V4:
  - Para referenciar entidades por clave usa `<assoc>_ID` (ej. `professional_ID_ID`, `client_ID_ID`). Si envías un objeto expandido, CAP espera `{ professional_ID: { ID: "..." } }`.
- 404 en acciones/updates:
  - La clave no existe (p. ej. `clientRequest_ID`). Valida IDs contra tus CSV de `db/data/*`.
- "no such table" al iniciar:
  - El runtime apunta a otra base (`db.sqlite`). Asegura `.cdsrc.json` con `credentials.url: db/sqlite.db` y corre `npm run deploy`.
- Emails no enviados:
  - Faltan variables SMTP (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`). Sin configuración, CAP omite el envío sin fallar.
- Node/paquetes SAP con warnings de engine:
  - En Node 22 pueden aparecer warnings; para BTP/HANA recomienda Node LTS (18/20).
 - Puerto en uso (`EADDRINUSE: :::4004`):
   - Detené el proceso que ocupa el puerto y reiniciá: `Stop-Process -Id <PID> -Force` en PowerShell; luego `npm start`.
 - Fiori Preview sin columnas:
   - Agregá `@UI.LineItem` y `@UI.SelectionFields` en el servicio (`srv/service.cds`). Reiniciá el servidor para recargar el modelo.

## Checklist de pruebas (2–3 minutos)

- Ver servicio y metadata:
  - `GET /odata/v4/service-connect/$metadata`
- Datos base:
  - `GET /odata/v4/service-connect/ServiceCategory`
  - `GET /odata/v4/service-connect/Professional`
- Review y rating:
  - Crear `Review` (ejemplo arriba) y luego `GET /Professional('<ID>')` para ver `rating` actualizado.
- Verificación y evento:
  - `PATCH /Professional('<ID>')` con `{ "isVerified": true }`.
  - Si SMTP configurado, revisar casilla del profesional.
- Nueva solicitud y notificación:
  - Crear `ClientRequest` (ejemplo arriba).
  - Verificar que el email fue enviado al profesional con mayor `rating` disponible en esa categoría.
- Asignación manual (opcional):
  - `POST /assignProfessional` con `clientRequest_ID` y `professional_ID`.
  - Confirmar en `GET /Assignment` que existe el vínculo.

- Asignación por cercanía (geo):
```
POST /odata/v4/service-connect/autoAssignNearest
Content-Type: application/json
{
  "clientRequest_ID": "99999999-9999-9999-9999-999999999999",
  "maxRadiusKm": 20
}
```
Luego:
  - `GET /odata/v4/service-connect/Assignment?$top=5` para ver el registro creado.
  - `GET /odata/v4/service-connect/ClientRequest('99999999-9999-9999-9999-999999999999')` para verificar `status: assigned`.
