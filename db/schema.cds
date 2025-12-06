namespace serviceconnect;

entity Professional {
  key ID           : UUID;
  fullName         : String(120);
  professionType   : String(80);          // plumber, electrician, lawyer, etc.
  trade_ID         : Association to Trade;
  registrationNumber : String(50);        // matrícula o título profesional
  email            : String(120);
  phone            : String(50);
  location         : String(120);
  latitude         : Decimal(9,6);
  longitude        : Decimal(9,6);
  rating           : Decimal(3,1);        // promedio de valoraciones
  availability     : Boolean;
  isVerified       : Boolean;
  createdAt        : Timestamp;
  updatedAt        : Timestamp;
}

entity ServiceCategory {
  key ID       : UUID;
  name         : String(100);
  description  : String(255);
}

entity ServiceOffering {
  key ID                : UUID;
  professional_ID       : Association to Professional;
  category_ID           : Association to ServiceCategory;
  description           : String(255);
  priceRange            : String(60);   // Ej: “$20.000 - $40.000”
  active                : Boolean;
  createdAt             : Timestamp;
}

entity ClientRequest {
  key ID            : UUID;
  clientName        : String(120);
  clientEmail       : String(120);
  client_ID         : Association to Client;
  serviceCategory_ID: Association to ServiceCategory;
  description       : String(255);
  location          : String(150);
  latitude          : Decimal(9,6);
  longitude         : Decimal(9,6);
  status            : String(40);     // pending, assigned, closed
  createdAt         : Timestamp;
}

entity Assignment {
  key ID              : UUID;
  professional_ID     : Association to Professional;
  clientRequest_ID    : Association to ClientRequest;
  dateAssigned        : DateTime;
  status              : String(40);  // accepted, rejected, completed
}

entity Review {
  key ID               : UUID;
  professional_ID      : Association to Professional;
  rating               : Decimal(3,1);
  comment              : String(255);
  createdAt            : Timestamp;
}

entity Client {
  key ID           : UUID;
  fullName         : String(120);
  email            : String(120);
  phone            : String(50);
  location         : String(150);
  createdAt        : Timestamp;
  updatedAt        : Timestamp;
}

entity Trade {
  key ID       : UUID;
  name         : String(80);
  description  : String(255);
  active       : Boolean;
}
