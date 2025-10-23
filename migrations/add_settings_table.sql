-- Add settings table for storing system configuration
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key);

-- Insert default setting for order prefix
INSERT INTO settings (key, value, description) VALUES
('order_prefix', 'ORD', 'Prefix used for order numbers (e.g., ORD-20240101-1234)')
ON CONFLICT (key) DO NOTHING;

-- Add other default settings if needed
INSERT INTO settings (key, value, description) VALUES
('base_fare', '5.00', 'Base fare amount for orders in AZN'),
('per_km_fare', '1.50', 'Fare per kilometer in AZN'),
('per_minute_fare', '0.50', 'Fare per minute in AZN'),
('minimum_fare', '3.00', 'Minimum fare for any order in AZN'),
('currency', 'AZN', 'Currency used in the system')
ON CONFLICT (key) DO NOTHING;

