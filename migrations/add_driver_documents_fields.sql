-- Migration: Add new fields to drivers table
-- Description: Add identity card, license images, actual address, expiry date and active status

-- Add new columns to drivers table
ALTER TABLE drivers 
ADD COLUMN IF NOT EXISTS identity_card_front VARCHAR(255),
ADD COLUMN IF NOT EXISTS identity_card_back VARCHAR(255),
ADD COLUMN IF NOT EXISTS license_front VARCHAR(255),
ADD COLUMN IF NOT EXISTS license_back VARCHAR(255),
ADD COLUMN IF NOT EXISTS actual_address TEXT,
ADD COLUMN IF NOT EXISTS license_expiry_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add comments for documentation
COMMENT ON COLUMN drivers.identity_card_front IS 'Şəxsiyyət vəsiqəsinin ön tərəfi';
COMMENT ON COLUMN drivers.identity_card_back IS 'Şəxsiyyət vəsiqəsinin arxa tərəfi';
COMMENT ON COLUMN drivers.license_front IS 'Sürücülük vəsiqəsinin ön tərəfi';
COMMENT ON COLUMN drivers.license_back IS 'Sürücülük vəsiqəsinin arxa tərəfi';
COMMENT ON COLUMN drivers.actual_address IS 'Faktiki ünvan';
COMMENT ON COLUMN drivers.license_expiry_date IS 'Sürücülük vəsiqəsinin bitmə tarixi';
COMMENT ON COLUMN drivers.is_active IS 'Sürücünün aktiv/deaktiv statusu';

-- Update existing drivers to be active by default
UPDATE drivers SET is_active = true WHERE is_active IS NULL;

-- Create index for better performance on active status
CREATE INDEX IF NOT EXISTS idx_drivers_is_active ON drivers(is_active);

-- Create index for license expiry date for monitoring
CREATE INDEX IF NOT EXISTS idx_drivers_license_expiry ON drivers(license_expiry_date);

-- Add constraint to ensure license expiry date is in the future for new drivers
-- (This will be enforced at application level, not database level for flexibility)
