using { serviceconnect } from '../db/schema';

service ServiceConnectService @(path: '/odata/v4/service-connect') {
  entity Professional      as projection on serviceconnect.Professional;
  entity Trade             as projection on serviceconnect.Trade;
  entity Client            as projection on serviceconnect.Client;
  entity ServiceCategory   as projection on serviceconnect.ServiceCategory;
  entity ServiceOffering   as projection on serviceconnect.ServiceOffering;
  entity ClientRequest     as projection on serviceconnect.ClientRequest;
  entity Assignment        as projection on serviceconnect.Assignment;
  entity Review            as projection on serviceconnect.Review;

  action assignProfessional(
    clientRequest_ID : UUID,
    professional_ID  : UUID
  ) returns Assignment;

  action autoAssignNearest(
    clientRequest_ID : UUID,
    maxRadiusKm      : Integer
  ) returns Assignment;
}

annotate ServiceConnectService.ServiceOffering with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: ID,           Label: 'ID' },
  { $Type: 'UI.DataField', Value: description,  Label: 'Descripción' },
  { $Type: 'UI.DataField', Value: priceRange,   Label: 'Rango de precio' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: category_ID, Label: 'Categoría', NavigationPropertyPath: category_ID },
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
    { $PropertyPath: active },
    { $PropertyPath: priceRange }
  ],
  Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Detalle', Target: '@UI.FieldGroup#Main' }
  ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
    { $Type: 'UI.DataField', Value: priceRange,  Label: 'Rango de precio' },
    { $Type: 'UI.DataField', Value: active,      Label: 'Activo' },
    { $Type: 'UI.DataField', Value: category_ID, Label: 'Categoría' },
    { $Type: 'UI.DataField', Value: professional_ID, Label: 'Profesional' }
  ]}
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
    Title: { Value: fullName },
    Description: { Value: professionType }
  },
  SelectionFields: [
    { $PropertyPath: fullName },
    { $PropertyPath: professionType },
    { $PropertyPath: location },
    { $PropertyPath: availability }
  ],
  Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'Perfil',   Target: '@UI.FieldGroup#Main' },
    { $Type: 'UI.ReferenceFacet', Label: 'Contacto', Target: '@UI.FieldGroup#Contact' },
    { $Type: 'UI.ReferenceFacet', Label: 'Rating',   Target: '@UI.DataPoint#Rating' }
  ],
  FieldGroup#Main: { Data: [
    { $Type: 'UI.DataField', Value: fullName,       Label: 'Nombre' },
    { $Type: 'UI.DataField', Value: professionType, Label: 'Profesión' },
    { $Type: 'UI.DataField', Value: location,       Label: 'Ubicación' },
    { $Type: 'UI.DataField', Value: registrationNumber, Label: 'Matrícula' },
    { $Type: 'UI.DataFieldWithNavigationPath', Value: trade_ID, Label: 'Oficio', NavigationPropertyPath: trade_ID }
  ]},
  FieldGroup#Contact: { Data: [
    { $Type: 'UI.DataField', Value: email, Label: 'Email' },
    { $Type: 'UI.DataField', Value: phone, Label: 'Teléfono' }
  ]},
  DataPoint#Rating: { Title: 'Rating', Value: rating }
};

annotate ServiceConnectService.ClientRequest with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: description, Label: 'Descripción' },
  { $Type: 'UI.DataField', Value: location,    Label: 'Ubicación' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: client_ID,   Label: 'Cliente',   NavigationPropertyPath: client_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: serviceCategory_ID, Label: 'Categoría', NavigationPropertyPath: serviceCategory_ID },
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
    { $Type: 'UI.DataField', Value: serviceCategory_ID, Label: 'Categoría' }
  ]}
};

annotate ServiceConnectService.Assignment with @UI.LineItem: [
  { $Type: 'UI.DataField', Value: ID,           Label: 'ID' },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: professional_ID, Label: 'Profesional', NavigationPropertyPath: professional_ID },
  { $Type: 'UI.DataFieldWithNavigationPath', Value: clientRequest_ID, Label: 'Solicitud', NavigationPropertyPath: clientRequest_ID },
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
  SelectionFields: [
    { $PropertyPath: name },
    { $PropertyPath: active }
  ],
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
  SelectionFields: [
    { $PropertyPath: fullName },
    { $PropertyPath: email },
    { $PropertyPath: location }
  ],
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
  SelectionFields: [
    { $PropertyPath: status },
    { $PropertyPath: dateAssigned }
  ]
};

annotate ServiceConnectService.Review with @UI: {
  HeaderInfo: {
    TypeName: 'Reseña',
    Title: { Value: rating },
    Description: { Value: comment }
  },
  SelectionFields: [
    { $PropertyPath: rating },
    { $PropertyPath: createdAt }
  ]
};
