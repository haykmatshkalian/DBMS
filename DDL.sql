DROP TABLE IF EXISTS reservation_rooms, payments, reviews, user_accounts, room_amenities, employees, reservations, customers, rooms,  invoices, hotels;
drop type if exists account_status, availability_status, hotel_employee_role,payment_method, payment_status, reservation_status, room_type, user_role;


CREATE TYPE account_status AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED','DELETED');
CREATE TYPE availability_status AS ENUM ('AVAILABLE', 'BOOKED', 'MAINTENANCE','OUT_OF_SERVICE');
CREATE TYPE hotel_employee_role AS ENUM ('MANAGER', 'RECEPTIONIST', 'HOUSEKEEPER','CHEF', 'SECURITY', 'ACCOUNTANT', 'TECHNICIAN');
CREATE TYPE payment_method AS ENUM ('CREDIT_CARD', 'DEBIT_CARD', 'PAYPAL','CASH', 'BANK_TRANSFER');
CREATE TYPE payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED','CANCELLED', 'REFUNDED');
CREATE TYPE reservation_status AS ENUM ('PENDING', 'CONFIRMED', 'CHECKED_IN','CHECKED_OUT', 'CANCELLED', 'NO_SHOW');
CREATE TYPE room_type AS ENUM ('SINGLE', 'DOUBLE', 'TWIN','SUITE', 'DELUXE', 'FAMILY', 'PRESIDENTIAL');
CREATE TYPE user_role AS ENUM ('MANAGER', 'RECEPTIONIST', 'HOUSEKEEPING','CUSTOMER', 'ADMIN', 'CHEF');


-- HOTELS
CREATE TABLE hotels (
                        hotel_id         SERIAL PRIMARY KEY,
                        hotel_name       VARCHAR(200) NOT NULL,
                        contact_number   VARCHAR(50) NOT NULL,
                        email            VARCHAR(200) NOT NULL,
                        city             VARCHAR(100) NOT NULL,
                        state            VARCHAR(100) NOT NULL,
                        country          VARCHAR(100) NOT NULL,
                        rating           NUMERIC(2,1) NOT NULL CHECK (rating >= 0 AND rating <= 5),
                        description      TEXT
);

-- EMPLOYEES (each employee belongs to a hotel)
CREATE TABLE employees (
                           staff_id   SERIAL PRIMARY KEY,
                           hotel_id   INT NOT NULL REFERENCES hotels(hotel_id) ON DELETE CASCADE,
                           first_name VARCHAR(100) not null,
                           last_name  VARCHAR(100) not null,
                           role       hotel_employee_role not null,
                           salary     NUMERIC(12,2) not null,
                           email      VARCHAR(200) not null,
                           phone      VARCHAR(30) not null
                           
);

-- ROOMS (each room belongs to one hotel)
CREATE TABLE rooms (
                       room_id             SERIAL PRIMARY KEY,
                       hotel_id            INT NOT NULL REFERENCES hotels(hotel_id) ON DELETE CASCADE,
                       room_number         VARCHAR(50) not null,
                       room_type           room_type,
                       capacity            INT,
                       availability_status availability_status,
                       price_per_night     NUMERIC(10,2),
                       description         TEXT,
                       CONSTRAINT ux_rooms_hotel_roomnumber UNIQUE (hotel_id, room_number)
);

-- ROOM_AMENITIES (1-to-many: each amenity row belongs to a specific room)
CREATE TABLE room_amenities (
                                amenity_id SERIAL PRIMARY KEY,
                                room_id    INT NOT NULL REFERENCES rooms(room_id) ON DELETE CASCADE,
                                description TEXT
);

-- CUSTOMERS
CREATE TABLE customers (
                           customer_id     SERIAL PRIMARY KEY,
                           first_name VARCHAR(100) NOT NULL,
                           last_name VARCHAR(100) NOT NULL,
                           email VARCHAR(200) NOT NULL,
                           phone VARCHAR(30) NOT NULL,
                           address TEXT NOT NULL,
                           date_registered DATE DEFAULT CURRENT_DATE
);

-- USER_ACCOUNTS (1:1 with customer)
CREATE TABLE user_accounts (
                               user_id       SERIAL PRIMARY KEY,
                               customer_id   INT UNIQUE REFERENCES customers(customer_id) ON DELETE CASCADE,
                               username      VARCHAR(100) NOT NULL UNIQUE,
                               password_hash VARCHAR(255) NOT NULL,
                               role user_role NOT NULL,
                               status account_status not null,
                               created_at    TIMESTAMP DEFAULT now()
);

-- REVIEWS (customer writes reviews for rooms)
CREATE TABLE reviews (
                         review_id   SERIAL PRIMARY KEY,
                         customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
                         room_id     INT NOT NULL REFERENCES rooms(room_id) ON DELETE CASCADE,
                         rating NUMERIC(2,1) CHECK (rating BETWEEN 1.0 AND 5.0),
                         comments    TEXT,
                         review_date DATE DEFAULT CURRENT_DATE
);

-- RESERVATIONS (customer makes reservation(s))
CREATE TABLE reservations (
                              reservation_id  SERIAL PRIMARY KEY,
                              customer_id     INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
                              reservation_date DATE DEFAULT CURRENT_DATE,
                              check_in_date    DATE not null,
                              check_out_date   DATE not null,
                              status           reservation_status,
                              total_amount     NUMERIC(12,2)
);

-- Junction table: which rooms are part of a reservation
CREATE TABLE reservation_rooms (
                        reservation_id  INT NOT NULL REFERENCES reservations(reservation_id) ON DELETE CASCADE,
                        room_id INT NOT NULL REFERENCES rooms(room_id) ON DELETE RESTRICT,
                        nights          INT,
                        price_per_night NUMERIC(10,2) NOT NULL,
                        quantity        INT NOT NULL DEFAULT 1,
                        PRIMARY KEY (reservation_id, room_id)
);


-- INVOICES
CREATE TABLE invoices (
                          invoice_id   SERIAL PRIMARY KEY,
                          invoice_date DATE DEFAULT CURRENT_DATE,
                          invoice_total NUMERIC(12,2) not null,
                          tax_amount   NUMERIC(12,2) not null,
                          notes        TEXT
);

-- PAYMENTS
CREATE TABLE payments (
                          payment_id     SERIAL PRIMARY KEY,
                          reservation_id INT NOT NULL REFERENCES reservations(reservation_id) ON DELETE CASCADE,
                          payment_date   TIMESTAMP DEFAULT now(),
                          payment_status payment_status NOT NULL,
                          payment_method payment_method NOT NULL,
                          amount_paid    NUMERIC(12,2) NOT NULL,
                          invoice_id     INT UNIQUE REFERENCES invoices(invoice_id) ON DELETE SET NULL
);

