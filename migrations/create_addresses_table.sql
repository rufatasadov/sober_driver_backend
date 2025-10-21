-- Create addresses table for local address storage with coordinates
CREATE TABLE IF NOT EXISTS addresses (
    id SERIAL PRIMARY KEY,
    address_text TEXT NOT NULL,
    formatted_address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    city VARCHAR(100),
    district VARCHAR(100),
    street VARCHAR(200),
    building_number VARCHAR(20),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Azerbaijan',
    search_keywords TEXT[], -- Array for fast searching
    popularity_score INTEGER DEFAULT 0, -- For ranking popular addresses
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for fast searching
    CONSTRAINT unique_address_coordinates UNIQUE (latitude, longitude)
);

-- Create indexes for fast searching
CREATE INDEX IF NOT EXISTS idx_addresses_search_keywords ON addresses USING GIN (search_keywords);
CREATE INDEX IF NOT EXISTS idx_addresses_address_text ON addresses USING GIN (to_tsvector('english', address_text));
CREATE INDEX IF NOT EXISTS idx_addresses_formatted_address ON addresses USING GIN (to_tsvector('english', formatted_address));
CREATE INDEX IF NOT EXISTS idx_addresses_city ON addresses (city);
CREATE INDEX IF NOT EXISTS idx_addresses_district ON addresses (district);
CREATE INDEX IF NOT EXISTS idx_addresses_street ON addresses (street);
CREATE INDEX IF NOT EXISTS idx_addresses_popularity ON addresses (popularity_score DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_addresses_updated_at
    BEFORE UPDATE ON addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_addresses_updated_at();

-- Insert some sample addresses for Baku, Azerbaijan
INSERT INTO addresses (address_text, formatted_address, latitude, longitude, city, district, street, building_number, search_keywords) VALUES
('28 May metro station, Baku', '28 May metro station, Baku, Azerbaijan', 40.3777, 49.8520, 'Baku', 'Nasimi', '28 May Street', '1', ARRAY['28', 'may', 'metro', 'station', 'baku', 'nasimi']),
('Fountain Square, Baku', 'Fountain Square, Baku, Azerbaijan', 40.3756, 49.8442, 'Baku', 'Sabail', 'Fountain Square', '1', ARRAY['fountain', 'square', 'baku', 'sabail', 'center']),
('Heydar Aliyev Center, Baku', 'Heydar Aliyev Center, Baku, Azerbaijan', 40.3953, 49.8672, 'Baku', 'Sabail', 'Heydar Aliyev Avenue', '1', ARRAY['heydar', 'aliyev', 'center', 'baku', 'museum']),
('Baku International Airport', 'Baku International Airport, Baku, Azerbaijan', 40.4675, 50.0467, 'Baku', 'Binagadi', 'Airport Road', '1', ARRAY['airport', 'baku', 'international', 'binagadi']),
('Port Baku Mall', 'Port Baku Mall, Baku, Azerbaijan', 40.3833, 49.8500, 'Baku', 'Sabail', 'Port Baku', '1', ARRAY['port', 'baku', 'mall', 'shopping', 'center']),
('Caspian Waterfront Mall', 'Caspian Waterfront Mall, Baku, Azerbaijan', 40.3667, 49.8333, 'Baku', 'Sabail', 'Caspian Waterfront', '1', ARRAY['caspian', 'waterfront', 'mall', 'baku']),
('Ganjlik Mall', 'Ganjlik Mall, Baku, Azerbaijan', 40.3833, 49.8500, 'Baku', 'Nasimi', 'Ganjlik', '1', ARRAY['ganjlik', 'mall', 'baku', 'nasimi']),
('Nizami Street, Baku', 'Nizami Street, Baku, Azerbaijan', 40.3756, 49.8442, 'Baku', 'Sabail', 'Nizami Street', '1', ARRAY['nizami', 'street', 'baku', 'sabail', 'shopping']),
('Baku State University', 'Baku State University, Baku, Azerbaijan', 40.3777, 49.8520, 'Baku', 'Nasimi', 'Z.Khalilov Street', '23', ARRAY['baku', 'state', 'university', 'bsu', 'nasimi']),
('Carpet Museum, Baku', 'Carpet Museum, Baku, Azerbaijan', 40.3667, 49.8333, 'Baku', 'Sabail', 'Carpet Museum', '1', ARRAY['carpet', 'museum', 'baku', 'sabail']);

-- Update popularity scores for commonly used addresses
UPDATE addresses SET popularity_score = 100 WHERE address_text LIKE '%metro%';
UPDATE addresses SET popularity_score = 90 WHERE address_text LIKE '%airport%';
UPDATE addresses SET popularity_score = 80 WHERE address_text LIKE '%mall%';
UPDATE addresses SET popularity_score = 70 WHERE address_text LIKE '%square%';
UPDATE addresses SET popularity_score = 60 WHERE address_text LIKE '%university%';
