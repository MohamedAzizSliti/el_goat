-- Create footballer_profiles table
CREATE TABLE IF NOT EXISTS footballer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    date_of_birth DATE,
    nationality TEXT,
    position TEXT,
    preferred_foot TEXT CHECK (preferred_foot IN ('left', 'right', 'both')),
    height_cm INTEGER CHECK (height_cm > 0 AND height_cm < 300),
    weight_kg INTEGER CHECK (weight_kg > 0 AND weight_kg < 200),
    experience_level TEXT CHECK (experience_level IN ('beginner', 'amateur', 'semi_professional', 'professional')),
    current_club TEXT,
    avatar_url TEXT,
    bio TEXT,
    xp_points INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create scout_profiles table
CREATE TABLE IF NOT EXISTS scout_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    country TEXT,
    city TEXT,
    scouting_level TEXT,
    experience_years INTEGER DEFAULT 0 CHECK (experience_years >= 0),
    bio TEXT,
    preferred_positions TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ,
    UNIQUE(user_id)
);

-- Create club_profiles table
CREATE TABLE IF NOT EXISTS club_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_name TEXT NOT NULL,
    location TEXT,
    website TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ,
    UNIQUE(user_id)
);

-- Create fan_profiles table
CREATE TABLE IF NOT EXISTS fan_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    country TEXT,
    city TEXT,
    favorite_team TEXT,
    favorite_player TEXT,
    bio TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_footballer_profiles_user_id ON footballer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_footballer_profiles_position ON footballer_profiles(position);
CREATE INDEX IF NOT EXISTS idx_footballer_profiles_nationality ON footballer_profiles(nationality);
CREATE INDEX IF NOT EXISTS idx_footballer_profiles_is_verified ON footballer_profiles(is_verified);
CREATE INDEX IF NOT EXISTS idx_footballer_profiles_created_at ON footballer_profiles(created_at);

CREATE INDEX IF NOT EXISTS idx_scout_profiles_user_id ON scout_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_scout_profiles_country ON scout_profiles(country);
CREATE INDEX IF NOT EXISTS idx_scout_profiles_scouting_level ON scout_profiles(scouting_level);
CREATE INDEX IF NOT EXISTS idx_scout_profiles_is_verified ON scout_profiles(is_verified);
CREATE INDEX IF NOT EXISTS idx_scout_profiles_specializations ON scout_profiles USING GIN(specializations);

CREATE INDEX IF NOT EXISTS idx_club_profiles_user_id ON club_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_club_profiles_country ON club_profiles(country);
CREATE INDEX IF NOT EXISTS idx_club_profiles_league ON club_profiles(league);
CREATE INDEX IF NOT EXISTS idx_club_profiles_is_verified ON club_profiles(is_verified);

CREATE INDEX IF NOT EXISTS idx_fan_profiles_user_id ON fan_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_fan_profiles_country ON fan_profiles(country);
CREATE INDEX IF NOT EXISTS idx_fan_profiles_is_verified ON fan_profiles(is_verified);

-- Create updated_at triggers for all profile tables
CREATE OR REPLACE FUNCTION update_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_footballer_profiles_updated_at
    BEFORE UPDATE ON footballer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_updated_at();

CREATE TRIGGER update_scout_profiles_updated_at
    BEFORE UPDATE ON scout_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_updated_at();

CREATE TRIGGER update_club_profiles_updated_at
    BEFORE UPDATE ON club_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_updated_at();

CREATE TRIGGER update_fan_profiles_updated_at
    BEFORE UPDATE ON fan_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_updated_at();

-- Enable Row Level Security (RLS) for all profile tables
ALTER TABLE footballer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE scout_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for footballer_profiles
CREATE POLICY "Users can view their own footballer profile" ON footballer_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own footballer profile" ON footballer_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own footballer profile" ON footballer_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own footballer profile" ON footballer_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Allow scouts to view footballer profiles for evaluation
CREATE POLICY "Scouts can view footballer profiles" ON footballer_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM scout_profiles
            WHERE scout_profiles.user_id = auth.uid()
        )
    );

-- Allow public viewing of verified footballer profiles
CREATE POLICY "Public can view verified footballer profiles" ON footballer_profiles
    FOR SELECT USING (is_verified = true);

-- RLS Policies for scout_profiles
CREATE POLICY "Users can view their own scout profile" ON scout_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own scout profile" ON scout_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own scout profile" ON scout_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own scout profile" ON scout_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Allow public viewing of verified scout profiles
CREATE POLICY "Public can view verified scout profiles" ON scout_profiles
    FOR SELECT USING (is_verified = true);

-- RLS Policies for club_profiles
CREATE POLICY "Users can view their own club profile" ON club_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own club profile" ON club_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own club profile" ON club_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own club profile" ON club_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Allow public viewing of verified club profiles
CREATE POLICY "Public can view verified club profiles" ON club_profiles
    FOR SELECT USING (is_verified = true);

-- RLS Policies for fan_profiles
CREATE POLICY "Users can view their own fan profile" ON fan_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own fan profile" ON fan_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own fan profile" ON fan_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own fan profile" ON fan_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Allow public viewing of verified fan profiles
CREATE POLICY "Public can view verified fan profiles" ON fan_profiles
    FOR SELECT USING (is_verified = true);

-- Create view for all profiles with user type
CREATE OR REPLACE VIEW all_profiles AS
SELECT
    'footballer' as profile_type,
    user_id,
    full_name,
    phone,
    nationality as country,
    NULL as city,
    position,
    current_club as organization,
    avatar_url,
    bio,
    is_verified,
    last_seen,
    created_at,
    updated_at
FROM footballer_profiles
UNION ALL
SELECT
    'scout' as profile_type,
    user_id,
    full_name,
    phone,
    country,
    city,
    scouting_level as position,
    organization,
    avatar_url,
    bio,
    is_verified,
    last_seen,
    created_at,
    updated_at
FROM scout_profiles
UNION ALL
SELECT
    'club' as profile_type,
    user_id,
    club_name as full_name,
    phone,
    country,
    city,
    league as position,
    club_name as organization,
    logo_url as avatar_url,
    description as bio,
    is_verified,
    last_seen,
    created_at,
    updated_at
FROM club_profiles
UNION ALL
SELECT
    'fan' as profile_type,
    user_id,
    full_name,
    phone,
    country,
    city,
    favorite_team as position,
    favorite_team as organization,
    avatar_url,
    bio,
    is_verified,
    last_seen,
    created_at,
    updated_at
FROM fan_profiles;

-- Grant access to the view
GRANT SELECT ON all_profiles TO authenticated;

-- Create RLS policy for the view
CREATE POLICY "Users can view profiles based on individual table policies" ON all_profiles
    FOR SELECT USING (true); -- Relies on underlying table policies

-- Comments for documentation
COMMENT ON TABLE footballer_profiles IS 'Profiles for football players with sports-specific information';
COMMENT ON TABLE scout_profiles IS 'Profiles for football scouts with scouting credentials and experience';
COMMENT ON TABLE club_profiles IS 'Profiles for football clubs with organizational information';
COMMENT ON TABLE fan_profiles IS 'Profiles for football fans with preferences and interests';
COMMENT ON VIEW all_profiles IS 'Unified view of all profile types for search and discovery';
