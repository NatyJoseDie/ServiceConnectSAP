# Flujo Frontend – ServiceConnect (UI5/Fiori)

## Objetivo
- Integrar el frontend (UI5/Fiori) con el backend CAP mediante OData V4.
- Documentar geolocalización y sistema de notificaciones para incorporarlos en la UI.

## Endpoints y Modelo
- Base OData: `http://localhost:4004/odata/v4/service-connect/` (`srv/service.cds:1`).
- Nota: el puerto puede variar según cómo se inicie CAP. Usá el que muestre el terminal (`[cds] - server listening on { url: 'http://localhost:<puerto>' }`).
- Entidades clave:
  - `Professional`, `Client`, `ClientRequest`, `Assignment`, `Review`, `ServiceCategory`, `ServiceOffering`.
- Modelo UI5:
  - `serviceUrl: "/odata/v4/service-connect/"` (`app/profesional-simple/webapp/manifest.json:15`).
  - Ejemplo de bind: `items="{/Professional}"` (`app/profesional-simple/webapp/view/Main.view.xml:7`).

## Geolocalización
- Campos de lat/lng:
  - `Professional.latitude`, `Professional.longitude` (`db/schema.cds:12`–`13`).
  - `ClientRequest.latitude`, `ClientRequest.longitude` (`db/schema.cds:49`–`50`).
- Búsqueda de cercanos:
  - Acción `findNearestProfessionals(lat, lng, specialization_ID, maxRadiusKm, limit)` (`srv/service.cds:23`–`31`).
  - Implementación con Haversine (`srv/service.js:22`–`30`, `srv/service.js:110`–`147`).
- Asignación automática por radio:
  - Acción `autoAssignNearest(clientRequest_ID, maxRadiusKm)` (`srv/service.cds:17`–`21`).
  - Usa la ubicación de la `ClientRequest` y calcula distancias (`srv/service.js:58`–`108`).
- Recomendaciones UI:
  - Al crear `ClientRequest`, capturar lat/lng del cliente y enviarlos junto con `location`.
  - Botón “Buscar cercanos” que llame `POST /autoAssignNearest` o `POST /findNearestProfessionals`.

## Sistema de Notificaciones (Email)
- Transporte configurable por variables de entorno:
  - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`.
  - Inicialización segura (`srv/service.js:4`–`20`).
- Envíos automáticos:
  - Al asignar cercano: mail al profesional (`srv/service.js:103`–`106`).
  - Al validar profesional (`Professional.isVerified = true`): mail de confirmación y evento interno (`srv/service.js:236`–`244`).
  - Al crear `ClientRequest`: mail al mejor profesional disponible (`srv/service.js:250`–`267`).
- Comportamiento sin SMTP:
  - Si faltan `SMTP_*`, el envío se omite sin fallar (`srv/service.js:15`–`20`).

## Mensajería In‑App
- Entidades: `MessageThread`, `Message` (`db/schema.cds:124`–`141`).
- Reglas:
  - Validación de contenido (`srv/service.js:149`–`152`).
  - Autocompletado de `createdAt` e `isRead` (`srv/service.js:153`–`158`).
  - Marcar leído: `action markMessageRead(message_ID)` (`srv/service.cds:33`, `srv/service.js:160`–`165`).

## Ratings y Validaciones
- Revisión obligatoria antes de completar `Assignment` (`srv/service.js:214`–`223`).
- Recalcular rating promedio del profesional después de cada `Review` (`srv/service.js:225`–`234`).

## Métricas para UI
- `metricsByCategory` (`srv/service.js:167`–`183`).
- `metricsByLocation` (`srv/service.js:185`–`194`).
- `metricsByRating` (`srv/service.js:196`–`205`).
- Útiles para KPIs, dashboards y filtros avanzados.

## Integración UI5/Fiori
- UI simple (sap.m):
  - Lista funcional en `app/profesional-simple/webapp` (`index.html:1`, `manifest.json:1`, `view/Main.view.xml:1`).
- Fiori Elements (List Report):
  - Recomendada con Fiori Tools (`yo @sap/fiori`) para evitar dependencias de CDN en local.
  - Configurar `serviceUrl` al endpoint CAP y `entitySet: "Professional"`.

## Variables de Entorno (Resumen)
- Email: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`.
- Sin estas variables, el sistema de notificaciones sigue operando silenciosamente sin enviar correos.

## Flujo Sugerido (UI)
- Crear `ClientRequest` con `location`, `latitude`, `longitude`.
- Ejecutar `autoAssignNearest` para asignar un profesional dentro del radio.
- Notificar al profesional asignado por email.
- Gestionar conversación `MessageThread` y `Message`; marcar mensajes como leídos con `markMessageRead`.
- Tras completar el trabajo, ingresar `Review`; el backend recalcula rating automáticamente.
