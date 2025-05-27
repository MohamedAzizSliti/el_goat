-- Add country column to club_profiles table
-- This migration adds the missing 'country' column that is expected by the application

-- Add country column to club_profiles table
ALTER TABLE club_profiles 
ADD COLUMN IF NOT EXISTS country TEXT;

-- Add index for better performance when filtering by country
CREATE INDEX IF NOT EXISTS idx_club_profiles_country ON club_profiles(country);

-- Add comment to document the column
COMMENT ON COLUMN club_profiles.country IS 'Country where the club is located (e.g., Tunisia, France, Spain)';
