-- Solo para una instalación nueva. No altera habitaciones existentes.
USE hotel_reservas;
INSERT INTO habitaciones(capacidad,descripcion,habilitada,numero,precio_noche,tipo)
SELECT 1,'Cama individual, baño privado y Wi-Fi',1,'101',90.00,'SIMPLE'
WHERE NOT EXISTS(SELECT 1 FROM habitaciones WHERE numero='101');
INSERT INTO habitaciones(capacidad,descripcion,habilitada,numero,precio_noche,tipo)
SELECT 2,'Dos camas, baño privado y escritorio',1,'102',145.00,'DOBLE'
WHERE NOT EXISTS(SELECT 1 FROM habitaciones WHERE numero='102');
INSERT INTO habitaciones(capacidad,descripcion,habilitada,numero,precio_noche,tipo)
SELECT 2,'Cama queen, vista exterior y minibar',1,'201',180.00,'MATRIMONIAL'
WHERE NOT EXISTS(SELECT 1 FROM habitaciones WHERE numero='201');
INSERT INTO habitaciones(capacidad,descripcion,habilitada,numero,precio_noche,tipo)
SELECT 3,'Dos camas y espacio para cama adicional',1,'202',150.00,'DOBLE'
WHERE NOT EXISTS(SELECT 1 FROM habitaciones WHERE numero='202');
INSERT INTO habitaciones(capacidad,descripcion,habilitada,numero,precio_noche,tipo)
SELECT 4,'Sala, cama king y vista panorámica',1,'301',320.00,'SUITE'
WHERE NOT EXISTS(SELECT 1 FROM habitaciones WHERE numero='301');
