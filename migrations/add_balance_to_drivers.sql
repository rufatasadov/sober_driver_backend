-- Migration: Add balance field to drivers table
-- Date: 2024-01-19

-- Add balance column to drivers table
ALTER TABLE drivers 
ADD COLUMN balance DECIMAL(10, 2) DEFAULT 0.00 NOT NULL;

-- Update existing drivers to have 0 balance
UPDATE drivers SET balance = 0.00 WHERE balance IS NULL;

-- Add comment to the column
COMMENT ON COLUMN drivers.balance IS 'Driver account balance in AZN';
