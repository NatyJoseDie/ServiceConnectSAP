# ServiceConnect – Demo y Guía Rápida

## Resumen
- Backend SAP CAP con OData V4 para profesionales, oficios y solicitudes.
- UI moderna SAPUI5 estilo Work Zone con FlexibleColumnLayout.
- Demo listo para mostrar CRUD (alta, edición, baja), chat y servicios.

## Quickstart
- `npm install`
- `npm run deploy`
- `npm start`
- Abrir UI: `http://localhost:4004/ui/profesional-modern/`
- Servicio OData: `http://localhost:4004/odata/v4/service-connect/`

## Qué Mostrar en el Demo
- Cards con KPIs y Acciones rápidas.
- Filtros y tabla con badges de disponibilidad.
- Click en fila → detalle; “Editar” → tercera columna.
- Botón “Nuevo” → registrar profesional (POST) y creación automática de conversación y oferta.
- Botón “Eliminar” en detalle (DELETE).
- Pestaña Chat: enviar mensajes (POST) y ver burbujas.

## Rutas y Vistas Clave
- `manifest.json` → `Route_Master`, `Route_Detail`, `Route_Edit`, `Route_Chat`, `Route_Register`.
- `view/App.view.xml` → FlexibleColumnLayout.
- `view/Master.view.xml` → listado, filtros y cards.
- `view/ProfessionalDetail.view.xml` → perfil y servicios.
- `view/ProfessionalEdit.view.xml` → edición.
- `view/ProfessionalRegister.view.xml` → alta.
- `view/Chat.view.xml` → chat.

## Deploy a SAP BTP (Cloud Foundry)
- Opción rápida: servir UI desde CAP (`srv/server.js`), `cf push` con `manifest.yml`.
- Opción enterprise: Approuter + HANA Cloud (MTA), `mbt build` y `cf deploy`.

## Notas
- OData V4 activo: CRUD completo en entidades principales.
- Para productivo: activar `@requires` y roles (XSUAA), mover DB a HANA.
