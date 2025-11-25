DROP TABLE IF EXISTS reservation_rooms, payments, reviews, user_accounts, room_amenities, employees, reservations, customers, rooms,  invoices, hotels;


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
                           role       VARCHAR(100) not null,
                           salary     NUMERIC(12,2) not null,
                           email      VARCHAR(200) not null,
                           phone      VARCHAR(30) not null
);

-- ROOMS (each room belongs to one hotel)
CREATE TABLE rooms (
                       room_id             SERIAL PRIMARY KEY,
                       hotel_id            INT NOT NULL REFERENCES hotels(hotel_id) ON DELETE CASCADE,
                       room_number         VARCHAR(50),
                       room_type           VARCHAR(100),
                       capacity            INT,
                       availability_status VARCHAR(50),
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
                           first_name      VARCHAR(100),
                           last_name       VARCHAR(100),
                           email           VARCHAR(200),
                           phone           VARCHAR(30),
                           address         TEXT,
                           date_registered DATE DEFAULT CURRENT_DATE
);

-- USER_ACCOUNTS (1:1 with customer)
CREATE TABLE user_accounts (
                               user_id       SERIAL PRIMARY KEY,
                               customer_id   INT UNIQUE REFERENCES customers(customer_id) ON DELETE CASCADE,
                               username      VARCHAR(100) NOT NULL UNIQUE,
                               password_hash VARCHAR(255) NOT NULL,
                               role VARCHAR(50) CHECK (role IN ('CUSTOMER','ADMIN','STAFF')),
                               status VARCHAR(50) CHECK (status IN ('ACTIVE','INACTIVE')),
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
                              check_in_date    DATE,
                              check_out_date   DATE,
                              status           VARCHAR(50),
                              total_amount     NUMERIC(12,2)
);

-- Junction table: which rooms are part of a reservation
CREATE TABLE reservation_rooms (
                                   reservation_id  INT NOT NULL REFERENCES reservations(reservation_id) ON DELETE CASCADE,
                                   room_id INT NOT NULL REFERENCES rooms(room_id) ON DELETE RESTRICT,
                                   nights          INT,
                                   price_per_night NUMERIC(10,2),
                                   PRIMARY KEY (reservation_id, room_id)
);

-- INVOICES
CREATE TABLE invoices (
                          invoice_id   SERIAL PRIMARY KEY,
                          invoice_date DATE DEFAULT CURRENT_DATE,
                          invoice_total NUMERIC(12,2),
                          tax_amount   NUMERIC(12,2),
                          notes        TEXT
);

-- PAYMENTS
CREATE TABLE payments (
                          payment_id     SERIAL PRIMARY KEY,
                          reservation_id INT NOT NULL REFERENCES reservations(reservation_id) ON DELETE CASCADE,
                          payment_date   TIMESTAMP DEFAULT now(),
                          payment_status VARCHAR(50),
                          payment_method VARCHAR(50),
                          amount_paid    NUMERIC(12,2),
                          invoice_id     INT UNIQUE REFERENCES invoices(invoice_id) ON DELETE SET NULL
);
