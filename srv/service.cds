using { serviceconnect } from '../db/schema';

service ServiceConnectService @(path: '/odata/v4/service-connect') {
  entity Professional      as projection on serviceconnect.Professional;
  entity Tradesman         as projection on serviceconnect.Tradesman;
  entity Trade             as projection on serviceconnect.Trade;
  entity Client            as projection on serviceconnect.Client;
  entity ServiceCategory   as projection on serviceconnect.ServiceCategory;
  entity ServiceOffering   as projection on serviceconnect.ServiceOffering;
  entity ClientRequest     as projection on serviceconnect.ClientRequest;
  entity Assignment        as projection on serviceconnect.Assignment;
  entity Review            as projection on serviceconnect.Review;
  entity Specialization    as projection on serviceconnect.Specialization;
  entity SubSpecialization as projection on serviceconnect.SubSpecialization;
  entity ProfessionalSpecialization as projection on serviceconnect.ProfessionalSpecialization;
  entity TradesmanSpecialization as projection on serviceconnect.TradesmanSpecialization;
  entity AvailabilitySlot  as projection on serviceconnect.AvailabilitySlot;
  entity MessageThread     as projection on serviceconnect.MessageThread;
  entity Message           as projection on serviceconnect.Message;

  action assignProfessional(
    clientRequest_ID : UUID,
    professional_ID  : UUID
  ) returns Assignment;

  action assignTradesman(
    clientRequest_ID : UUID,
    tradesman_ID     : UUID
  ) returns Assignment;

  action autoAssignNearest(
    clientRequest_ID : UUID,
    maxRadiusKm      : Integer
  ) returns Assignment;

  action findNearestProfessionals(
    lat               : Decimal(9,6),
    lng               : Decimal(9,6),
    specialization_ID : UUID,
    maxRadiusKm       : Integer,
    limit             : Integer
  ) returns array of serviceconnect.NearbyProfessionalResult;

  action findNearestTradesmen(
    lat               : Decimal(9,6),
    lng               : Decimal(9,6),
    specialization_ID : UUID,
    maxRadiusKm       : Integer,
    limit             : Integer
  ) returns array of serviceconnect.NearbyTradesmanResult;

  action markMessageRead(message_ID : UUID) returns Boolean;

  action metricsByCategory() returns array of serviceconnect.CategoryMetric;
  action metricsByLocation() returns array of serviceconnect.LocationMetric;
  action metricsByRating() returns array of serviceconnect.RatingBucket;
}

annotate ServiceConnectService.ServiceOffering with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: ID,           Label: 'ID' },
  { $Type: 'UI.DataField', Value: description,  Label: 'Descripción' },
  { $Type: 'UI.DataField', Value: priceRange,   Label: 'Rango de precio' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: category_ID, Label: 'Categoría', NavigationPropertyPath: category_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: specialization_ID, Label: 'Especialidad', NavigationPropertyPath: specialization_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: subSpecialization_ID, Label: 'Sub‑especialidad', NavigationPropertyPath: subSpecialization_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: professional_ID, Label: 'Profesional', NavigationPropertyPath: professional_ID },
  { $Type: 'UI.DataField', Value: active,       Label: 'Activo' },
  { $Type: 'UI.DataField', Value: createdAt,    Label: 'Creado' }
];

annotate ServiceConnectService.ServiceOffering with @UI: {
  HeaderInfo: {
    TypeName: 'Servicio',
    Title: { Value: description },
    Description: { Value: priceRange }
  },
  SelectionFields: [
    { $PropertyPath: description },
    { $PropertyPath: priceRange },
    { $PropertyPath: active }
  ],
  Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' }
  ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
    { $Type: 'UI.DataField', Value: priceRange,  Label: 'Rango de precio' },
    { $Type: 'UI.DataField', Value: active,      Label: 'Activo' },
    { $Type: 'UI.DataField', Value: category_ID, Label: 'Categoría' },
    { $Type: 'UI.DataFieldWithNavigationPath', Value: specialization_ID, Label: 'Especialidad', NavigationPropertyPath: specialization_ID },
    { $Type: 'UI.DataFieldWithNavigationPath', Value: subSpecialization_ID, Label: 'Sub‑especialidad', NavigationPropertyPath: subSpecialization_ID },
    { $Type: 'UI.DataField', Value: professional_ID, Label: 'Profesional' }
  ]}
};
annotate ServiceConnectService.ServiceOffering with @UI.PresentationVariant: {
  SortOrder: [ { Property: createdAt, Descending: true } ],
  RequestAtLeast: [ description, priceRange, active ]
};

annotate ServiceConnectService.Professional with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: fullName,       Label: 'Nombre' },
  { $Type: 'UI.DataField', Value: professionType, Label: 'Profesión' },
  { $Type: 'UI.DataField', Value: location,       Label: 'Ubicación' },
  { $Type: 'UI.DataField', Value: rating,         Label: 'Rating' },
  { $Type: 'UI.DataField', Value: availability,   Label: 'Disponible' }
];
annotate ServiceConnectService.Professional with @UI.PresentationVariant: {
  SortOrder: [ { Property: rating, Descending: true } ],
  RequestAtLeast: [ fullName, rating, location ]
};

annotate ServiceConnectService.Professional with @UI: {
  HeaderInfo: {
    TypeName: 'Profesional',
    TypeNamePlural: 'Profesionales',
    Title: { Value: fullName },
    Description: { Value: professionType },
    ImageUrl: 'https://ui5.sap.com/test-resources/sap/ui/documentation/sdk/images/HT-1000.jpg' // Placeholder visual
  },
  SelectionFields: [
    { $PropertyPath: professionType },
    { $PropertyPath: location },
    { $PropertyPath: rating }
  ],
  LineItem: [
    { $Type: 'UI.DataField', Value: fullName,       Label: 'Nombre' },
    { $Type: 'UI.DataField', Value: professionType, Label: 'Profesión', Criticality: #Information },
    { $Type: 'UI.DataField', Value: location,       Label: 'Ubicación' },
    { $Type: 'UI.DataFieldForAnnotation', Target: '@UI.DataPoint#RatingIndicator', Label: 'Calificación' },
    { $Type: 'UI.DataField', Value: availability,   Label: 'Disponible', Criticality: #Positive }
  ],
  Facets: [
    { $Type: 'UI.CollectionFacet', Label: 'Información General', ID: 'GeneralInfo', Facets: [
        { $Type: 'UI.ReferenceFacet', Label: 'Datos de Contacto', Target: '@UI.FieldGroup#Contact' },
        { $Type: 'UI.ReferenceFacet', Label: 'Detalles Profesionales', Target: '@UI.FieldGroup#ProfessionalDetails' }
    ]},
    { $Type: 'UI.ReferenceFacet', Label: 'Disponibilidad', Target: '@UI.LineItem#Availability' }
  ],
  FieldGroup#Contact: { Data: [
    { $Type: 'UI.DataField', Value: email, Label: 'Correo Electrónico', IconUrl: 'sap-icon://email' },
    { $Type: 'UI.DataField', Value: phone, Label: 'Teléfono', IconUrl: 'sap-icon://phone' },
    { $Type: 'UI.DataField', Value: location, Label: 'Dirección' }
  ]},
  FieldGroup#ProfessionalDetails: { Data: [
    { $Type: 'UI.DataField', Value: registrationNumber, Label: 'Matrícula' },
    { $Type: 'UI.DataField', Value: isVerified, Label: 'Verificado' },
    { $Type: 'UI.DataFieldWithNavigationPath', Value: trade_ID, Label: 'Oficio Principal', NavigationPropertyPath: trade },
  ]},
  DataPoint#RatingIndicator: {
    Value: rating,
    Title: 'Rating',
    TargetValue: 5,
    Visualization: #Rating
  },
  DataPoint#Rating: { Title: 'Rating Promedio', Value: rating, Visualization: #Rating }
};

annotate ServiceConnectService.ClientRequest with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
  { $Type: 'UI.DataField', Value: location,    Label: 'Ubicación' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: client_ID,   Label: 'Cliente',   NavigationPropertyPath: client_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: serviceCategory_ID, Label: 'Categoría', NavigationPropertyPath: serviceCategory_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: specialization_ID, Label: 'Especialidad', NavigationPropertyPath: specialization_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: subSpecialization_ID, Label: 'Sub‑especialidad', NavigationPropertyPath: subSpecialization_ID },
  { $Type: 'UI.DataField', Value: status,      Label: 'Estado' },
  { $Type: 'UI.DataField', Value: createdAt,   Label: 'Creado' }
];

annotate ServiceConnectService.ClientRequest with @UI: {
  HeaderInfo: {
    TypeName: 'Solicitud',
    Title: { Value: description },
    Description: { Value: status }
  },
  SelectionFields: [
    { $PropertyPath: status },
    { $PropertyPath: location },
    { $PropertyPath: createdAt }
  ],
  Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' }
  ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
    { $Type: 'UI.DataField', Value: location,    Label: 'Ubicación' },
    { $Type: 'UI.DataField', Value: status,      Label: 'Estado' },
    { $Type: 'UI.DataField', Value: createdAt,   Label: 'Creado' },
    { $Type: 'UI.DataField', Value: client_ID,   Label: 'Cliente' },
    { $Type: 'UI.DataField', Value: serviceCategory_ID, Label: 'Categoría' },
    { $Type: 'UI.DataField', Value: specialization_ID, Label: 'Especialidad' },
    { $Type: 'UI.DataField', Value: subSpecialization_ID, Label: 'Sub‑especialidad' }
  ]}
};
annotate ServiceConnectService.ClientRequest with @UI.PresentationVariant: {
  SortOrder: [ { Property: createdAt, Descending: true } ],
  RequestAtLeast: [ description, status, location ]
};

annotate ServiceConnectService.Assignment with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: ID,           Label: 'ID' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: professional_ID, Label: 'Profesional', NavigationPropertyPath: professional },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: clientRequest_ID, Label: 'Solicitud', NavigationPropertyPath: clientRequest },
  { $Type: 'UI.DataField', Value: dateAssigned, Label: 'Fecha asignación' },
  { $Type: 'UI.DataField', Value: status,       Label: 'Estado' }
];

annotate ServiceConnectService.Review with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: rating,    Label: 'Rating' },
  { $Type: 'UI.DataField', Value: comment,   Label: 'Comentario' },
  { $Type: 'UI.DataField', Value: createdAt, Label: 'Creado' }
];

annotate ServiceConnectService.Trade with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
  { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
  { $Type: 'UI.DataField', Value: active,      Label: 'Activo' }
];
annotate ServiceConnectService.Trade with @UI: {
  HeaderInfo: {
    TypeName: 'Oficio',
    Title: { Value: name },
    Description: { Value: description }
  },
  SelectionFields: [ { $PropertyPath: name }, { $PropertyPath: active } ],
  Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' }
  ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
    { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
    { $Type: 'UI.DataField', Value: active,      Label: 'Activo' }
  ]}
};

annotate ServiceConnectService.Client with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: fullName,   Label: 'Nombre' },
  { $Type: 'UI.DataField', Value: email,      Label: 'Email' },
  { $Type: 'UI.DataField', Value: phone,      Label: 'Teléfono' },
  { $Type: 'UI.DataField', Value: location,   Label: 'Ubicación' },
  { $Type: 'UI.DataField', Value: createdAt,  Label: 'Creado' }
];
annotate ServiceConnectService.Client with @UI: {
  HeaderInfo: {
    TypeName: 'Cliente',
    Title: { Value: fullName },
    Description: { Value: email }
  },
  SelectionFields: [ { $PropertyPath: fullName }, { $PropertyPath: email }, { $PropertyPath: location } ],
  Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' }
  ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: fullName,  Label: 'Nombre' },
    { $Type: 'UI.DataField', Value: email,     Label: 'Email' },
    { $Type: 'UI.DataField', Value: phone,     Label: 'Teléfono' },
    { $Type: 'UI.DataField', Value: location,  Label: 'Ubicación' }
  ]}
};

annotate ServiceConnectService.ServiceCategory with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
  { $Type: 'UI.DataField', Value: description, Label: 'Descripción' }
];
annotate ServiceConnectService.ServiceCategory with @UI: {
  HeaderInfo: {
    TypeName: 'Categoría de servicio',
    Title: { Value: name },
    Description: { Value: description }
  },
  SelectionFields: [ { $PropertyPath: name } ],
  Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' }
  ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
    { $Type: 'UI.DataField', Value: description, Label: 'Descripción' }
  ]}
};

annotate ServiceConnectService.Assignment with @UI: {
  HeaderInfo: {
    TypeName: 'Asignación',
    Title: { Value: status },
    Description: { Value: dateAssigned }
  },
  SelectionFields: [ { $PropertyPath: status }, { $PropertyPath: dateAssigned } ]
};
annotate ServiceConnectService.Assignment with @UI.PresentationVariant: {
  SortOrder: [ { Property: dateAssigned, Descending: true } ],
  RequestAtLeast: [ status, dateAssigned ]
};

annotate ServiceConnectService.Review with @UI: {
  HeaderInfo: {
    TypeName: 'Reseña',
    Title: { Value: rating },
    Description: { Value: comment }
  },
  SelectionFields: [ { $PropertyPath: rating }, { $PropertyPath: createdAt } ]
};
annotate ServiceConnectService.Review with @UI.PresentationVariant: {
  SortOrder: [ { Property: createdAt, Descending: true } ],
  RequestAtLeast: [ rating, comment, createdAt ]
};
annotate ServiceConnectService.Specialization with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
  { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: trade_ID, Label: 'Oficio', NavigationPropertyPath: trade },
  { $Type: 'UI.DataField', Value: active,      Label: 'Activo' }
];
annotate ServiceConnectService.Specialization with @UI: {
  HeaderInfo: {
    TypeName: 'Especialidad',
    Title: { Value: name },
    Description: { Value: description }
  },
  SelectionFields: [ { $PropertyPath: name }, { $PropertyPath: active } ],
  Facets: [ { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' } ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
    { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
    { $Type: 'UI.DataFieldWithNavigationPath', Value: trade_ID, Label: 'Oficio', NavigationPropertyPath: trade },
    { $Type: 'UI.DataField', Value: active,      Label: 'Activo' }
  ]}
};

annotate ServiceConnectService.SubSpecialization with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
  { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: specialization_ID, Label: 'Especialidad', NavigationPropertyPath: specialization_ID },
  { $Type: 'UI.DataField', Value: active,      Label: 'Activo' }
];
annotate ServiceConnectService.SubSpecialization with @UI: {
  HeaderInfo: {
    TypeName: 'Sub‑especialidad',
    Title: { Value: name },
    Description: { Value: description }
  },
  SelectionFields: [ { $PropertyPath: name }, { $PropertyPath: active } ],
  Facets: [ { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' } ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: name,        Label: 'Nombre' },
    { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
    { $Type: 'UI.DataFieldWithNavigationPath', Value: specialization_ID, Label: 'Especialidad', NavigationPropertyPath: specialization_ID },
    { $Type: 'UI.DataField', Value: active,      Label: 'Activo' }
  ]}
};

annotate ServiceConnectService.ProfessionalSpecialization with @UI.LineItem: [
  { $Type: 'UI.DataFieldWithNavigationPath', Value: professional_ID, Label: 'Profesional', NavigationPropertyPath: professional_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: specialization_ID, Label: 'Especialidad', NavigationPropertyPath: specialization_ID },
  { $Type: 'UI.DataField', Value: primary, Label: 'Principal' },
  { $Type: 'UI.DataField', Value: createdAt, Label: 'Creado' }
];
annotate ServiceConnectService.ProfessionalSpecialization with @UI: {
  HeaderInfo: {
    TypeName: 'Vínculo Profesional–Especialidad',
    Title: { Value: primary },
    Description: { Value: createdAt }
  },
  SelectionFields: [ { $PropertyPath: primary }, { $PropertyPath: createdAt } ]
};
annotate ServiceConnectService.AvailabilitySlot with @UI.LineItem: [
  { $Type: 'UI.DataFieldWithNavigationPath', Value: professional_ID, Label: 'Profesional', NavigationPropertyPath: professional_ID },
  { $Type: 'UI.DataField', Value: dayOfWeek, Label: 'Día' },
  { $Type: 'UI.DataField', Value: startTime, Label: 'Desde' },
  { $Type: 'UI.DataField', Value: endTime, Label: 'Hasta' },
  { $Type: 'UI.DataField', Value: urgent, Label: 'Urgencias' },
  { $Type: 'UI.DataField', Value: isActive, Label: 'Activo' }
];
annotate ServiceConnectService.AvailabilitySlot with @UI: {
  HeaderInfo: {
    TypeName: 'Disponibilidad',
    Title: { Value: startTime },
    Description: { Value: endTime }
  },
  SelectionFields: [ { $PropertyPath: dayOfWeek }, { $PropertyPath: isActive } ]
};

annotate ServiceConnectService.MessageThread with @UI.LineItem: [
  { $Type: 'UI.DataFieldWithNavigationPath', Value: clientRequest_ID, Label: 'Solicitud', NavigationPropertyPath: clientRequest_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: professional_ID, Label: 'Profesional', NavigationPropertyPath: professional_ID },
  { $Type: 'UI.DataField', Value: status, Label: 'Estado' },
  { $Type: 'UI.DataField', Value: createdAt, Label: 'Creado' }
];
annotate ServiceConnectService.MessageThread with @UI: {
  HeaderInfo: {
    TypeName: 'Conversación',
    Title: { Value: status },
    Description: { Value: createdAt }
  },
  SelectionFields: [ { $PropertyPath: status }, { $PropertyPath: createdAt } ]
};

annotate ServiceConnectService.Message with @UI.LineItem: [
  { $Type: 'UI.DataFieldWithNavigationPath', Value: thread_ID, Label: 'Hilo', NavigationPropertyPath: thread_ID },
  { $Type: 'UI.DataField', Value: senderRole, Label: 'Rol' },
  { $Type: 'UI.DataField', Value: content, Label: 'Mensaje' },
  { $Type: 'UI.DataField', Value: createdAt, Label: 'Creado' },
  { $Type: 'UI.DataField', Value: isRead, Label: 'Leído' }
];
annotate ServiceConnectService.Message with @UI: {
  HeaderInfo: {
    TypeName: 'Mensaje',
    Title: { Value: senderRole },
    Description: { Value: createdAt }
  },
  SelectionFields: [ { $PropertyPath: senderRole }, { $PropertyPath: isRead } ]
};
