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
  specialization_ID     : Association to Specialization;
  subSpecialization_ID  : Association to SubSpecialization;
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
  specialization_ID : Association to Specialization;
  subSpecialization_ID : Association to SubSpecialization;
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
  clientRequest_ID     : Association to ClientRequest;
  client_ID            : Association to Client;
  rating               : Decimal(3,1) not null;
  comment              : String(255) not null;
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

entity Specialization {
  key ID       : UUID;
  name         : String(100);
  description  : String(255);
  trade_ID     : Association to Trade;
  active       : Boolean;
}

entity SubSpecialization {
  key ID                 : UUID;
  name                   : String(100);
  description            : String(255);
  specialization_ID      : Association to Specialization;
  active                 : Boolean;
}

entity ProfessionalSpecialization {
  key ID              : UUID;
  professional_ID     : Association to Professional;
  specialization_ID   : Association to Specialization;
  primary             : Boolean;
  createdAt           : Timestamp;
}

entity AvailabilitySlot {
  key ID              : UUID;
  professional_ID     : Association to Professional;
  dayOfWeek           : Integer;     // 0=Dom, 1=Lun, ... 6=Sab
  startTime           : Time;
  endTime             : Time;
  urgent              : Boolean;
  isActive            : Boolean;
}

entity MessageThread {
  key ID                 : UUID;
  clientRequest_ID       : Association to ClientRequest;
  professional_ID        : Association to Professional;
  createdAt              : Timestamp;
  status                 : String(30); // open, closed
}

entity Message {
  key ID                 : UUID;
  thread_ID              : Association to MessageThread;
  senderRole             : String(20); // client, professional, admin
  senderProfessional_ID  : Association to Professional;
  senderClient_ID        : Association to Client;
  content                : String(1000) not null;
  createdAt              : Timestamp;
  isRead                 : Boolean;
}

type NearbyProfessionalResult {
  professional_ID : Association to Professional;
  fullName        : String(120);
  tradeName       : String(80);
  latitude        : Decimal(9,6);
  longitude       : Decimal(9,6);
  distanceKm      : Decimal(6,2);
  rating          : Decimal(3,1);
}

type CategoryMetric {
  category_ID : UUID;
  count       : Integer;
  avgRating   : Decimal(3,1);
}

type LocationMetric {
  location : String(150);
  count    : Integer;
}

type RatingBucket {
  rating : Decimal(3,1);
  count  : Integer;
}
