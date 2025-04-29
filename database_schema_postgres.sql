-- SQL Schema for CRM Dedetizadoras
-- Target Database: PostgreSQL (Supabase)

-- Users Table: Stores login information and roles for system users.
CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL, -- Store hashed passwords
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  role VARCHAR(20) NOT NULL DEFAULT 'technician' CHECK (role IN ('admin', 'manager', 'technician')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clients Table: Stores information about the customers.
CREATE TABLE IF NOT EXISTS clients (
  client_id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(100),
  address_street VARCHAR(255),
  address_number VARCHAR(20),
  address_complement VARCHAR(100),
  address_neighborhood VARCHAR(100),
  address_city VARCHAR(100),
  address_state VARCHAR(50),
  address_zipcode VARCHAR(15),
  address_latitude DECIMAL(10, 8), -- For Google Maps integration
  address_longitude DECIMAL(11, 8), -- For Google Maps integration
  segment VARCHAR(20) NOT NULL CHECK (segment IN ('Residencial', 'Comercial', 'Condomínio', 'Industrial')),
  created_by_user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pests Table: Optional table to standardize pest types.
CREATE TABLE IF NOT EXISTS pests (
  pest_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);

-- Products Table: Optional table to standardize products used.
CREATE TABLE IF NOT EXISTS products (
  product_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);

-- Services Table: Records details of each service performed.
CREATE TABLE IF NOT EXISTS services (
  service_id SERIAL PRIMARY KEY,
  client_id INTEGER NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
  service_date TIMESTAMP NOT NULL,
  pest_type_description VARCHAR(255), -- Free text if not using pests table
  -- pest_id INTEGER REFERENCES pests(pest_id) ON DELETE SET NULL, -- Uncomment if using pests table
  location_details VARCHAR(255), -- Specific location within the client address, e.g., Kitchen, Garden
  products_used_description TEXT, -- Free text if not using products table
  -- Consider a linking table if multiple products are used and Products table exists
  notes TEXT,
  performed_by_user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service Photos Table: Stores paths/URLs to before/after photos for services.
CREATE TABLE IF NOT EXISTS service_photos (
  photo_id SERIAL PRIMARY KEY,
  service_id INTEGER NOT NULL REFERENCES services(service_id) ON DELETE CASCADE,
  photo_url VARCHAR(512) NOT NULL, -- URL or path to the stored image file
  description VARCHAR(100), -- e.g., Before, After, Evidence
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Guarantees Table: Manages service guarantees.
CREATE TABLE IF NOT EXISTS guarantees (
  guarantee_id SERIAL PRIMARY KEY,
  service_id INTEGER NOT NULL UNIQUE REFERENCES services(service_id) ON DELETE CASCADE, -- Assuming one guarantee per service
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  duration_months INTEGER, -- Calculated or stored duration in months
  certificate_url VARCHAR(512), -- Path/URL to the generated certificate PDF
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications Table: Stores scheduled and sent notifications.
CREATE TABLE IF NOT EXISTS notifications (
  notification_id SERIAL PRIMARY KEY,
  client_id INTEGER REFERENCES clients(client_id) ON DELETE CASCADE,
  related_id INTEGER, -- Generic ID for related entity (e.g., guarantee_id)
  notification_type VARCHAR(50) NOT NULL, -- e.g., 'GuaranteeExpiryReminder', 'RevisitReminder', 'Custom'
  message TEXT NOT NULL,
  scheduled_send_date TIMESTAMP,
  actual_send_date TIMESTAMP,
  status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Sent', 'Failed', 'Cancelled')),
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add Indexes for performance
CREATE INDEX IF NOT EXISTS idx_client_name ON clients(name);
CREATE INDEX IF NOT EXISTS idx_client_phone ON clients(phone);
CREATE INDEX IF NOT EXISTS idx_client_email ON clients(email);
CREATE INDEX IF NOT EXISTS idx_service_date ON services(service_date);
CREATE INDEX IF NOT EXISTS idx_guarantee_end_date ON guarantees(end_date);
CREATE INDEX IF NOT EXISTS idx_notification_status_schedule ON notifications(status, scheduled_send_date);

-- Create trigger functions to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for each table with updated_at column
CREATE TRIGGER update_users_modtime
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_clients_modtime
BEFORE UPDATE ON clients
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_services_modtime
BEFORE UPDATE ON services
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_guarantees_modtime
BEFORE UPDATE ON guarantees
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_notifications_modtime
BEFORE UPDATE ON notifications
FOR EACH ROW EXECUTE FUNCTION update_modified_column();
