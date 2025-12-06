const cds = require('@sap/cds')
cds.on('bootstrap', app => {
  const express = require('express')
  app.use('/ui/profesional-modern', express.static('app/profesional-modern/webapp'))
})
module.exports = cds.server
