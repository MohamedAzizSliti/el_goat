-- Create user_roles table to track user types
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('footballer', 'scout', 'club', 'fan', 'admin')),
    is_primary BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, role)
);

-- Create index for user_roles
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_is_primary ON user_roles(is_primary);

-- Enable RLS for user_roles
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_roles
CREATE POLICY "Users can view their own roles" ON user_roles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own roles" ON user_roles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own roles" ON user_roles
    FOR UPDATE USING (auth.uid() = user_id);

-- Function to get user's primary role
CREATE OR REPLACE FUNCTION get_user_primary_role(target_user_id UUID DEFAULT auth.uid())
RETURNS TEXT AS $$
DECLARE
    primary_role TEXT;
BEGIN
    SELECT role INTO primary_role
    FROM user_roles
    WHERE user_id = target_user_id AND is_primary = true
    LIMIT 1;
    
    RETURN primary_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has specific role
CREATE OR REPLACE FUNCTION user_has_role(target_user_id UUID, check_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = target_user_id AND role = check_role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user profile based on their primary role
CREATE OR REPLACE FUNCTION get_user_profile(target_user_id UUID DEFAULT auth.uid())
RETURNS TABLE (
    profile_type TEXT,
    user_id UUID,
    full_name TEXT,
    phone TEXT,
    country TEXT,
    city TEXT,
    position TEXT,
    organization TEXT,
    avatar_url TEXT,
    bio TEXT,
    is_verified BOOLEAN,
    last_seen TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    additional_data JSONB
) AS $$
DECLARE
    primary_role TEXT;
BEGIN
    -- Get user's primary role
    SELECT get_user_primary_role(target_user_id) INTO primary_role;
    
    -- Return profile based on role
    CASE primary_role
        WHEN 'footballer' THEN
            RETURN QUERY
            SELECT 
                'footballer'::TEXT,
                fp.user_id,
                fp.full_name,
                fp.phone,
                fp.nationality,
                NULL::TEXT as city,
                fp.position,
                fp.current_club,
                fp.avatar_url,
                fp.bio,
                fp.is_verified,
                fp.last_seen,
                fp.created_at,
                fp.updated_at,
                jsonb_build_object(
                    'date_of_birth', fp.date_of_birth,
                    'preferred_foot', fp.preferred_foot,
                    'height_cm', fp.height_cm,
                    'weight_kg', fp.weight_kg,
                    'experience_level', fp.experience_level,
                    'xp_points', fp.xp_points
                ) as additional_data
            FROM footballer_profiles fp
            WHERE fp.user_id = target_user_id;
            
        WHEN 'scout' THEN
            RETURN QUERY
            SELECT 
                'scout'::TEXT,
                sp.user_id,
                sp.full_name,
                sp.phone,
                sp.country,
                sp.city,
                sp.scouting_level,
                sp.organization,
                sp.avatar_url,
                sp.bio,
                sp.is_verified,
                sp.last_seen,
                sp.created_at,
                sp.updated_at,
                jsonb_build_object(
                    'years_experience', sp.years_experience,
                    'specializations', sp.specializations
                ) as additional_data
            FROM scout_profiles sp
            WHERE sp.user_id = target_user_id;
            
        WHEN 'club' THEN
            RETURN QUERY
            SELECT 
                'club'::TEXT,
                cp.user_id,
                cp.club_name,
                cp.phone,
                cp.country,
                cp.city,
                cp.league,
                cp.club_name,
                cp.logo_url,
                cp.description,
                cp.is_verified,
                cp.last_seen,
                cp.created_at,
                cp.updated_at,
                jsonb_build_object(
                    'founded_year', cp.founded_year,
                    'division', cp.division,
                    'stadium_name', cp.stadium_name,
                    'capacity', cp.capacity,
                    'website_url', cp.website_url
                ) as additional_data
            FROM club_profiles cp
            WHERE cp.user_id = target_user_id;
            
        WHEN 'fan' THEN
            RETURN QUERY
            SELECT 
                'fan'::TEXT,
                fanp.user_id,
                fanp.full_name,
                fanp.phone,
                fanp.country,
                fanp.city,
                fanp.favorite_team,
                fanp.favorite_team,
                fanp.avatar_url,
                fanp.bio,
                fanp.is_verified,
                fanp.last_seen,
                fanp.created_at,
                fanp.updated_at,
                jsonb_build_object(
                    'favorite_player', fanp.favorite_player
                ) as additional_data
            FROM fan_profiles fanp
            WHERE fanp.user_id = target_user_id;
            
        ELSE
            -- Return empty result if no profile found
            RETURN;
    END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search profiles across all types
CREATE OR REPLACE FUNCTION search_profiles(
    search_query TEXT DEFAULT '',
    profile_types TEXT[] DEFAULT ARRAY['footballer', 'scout', 'club', 'fan'],
    country_filter TEXT DEFAULT NULL,
    verified_only BOOLEAN DEFAULT FALSE,
    limit_count INTEGER DEFAULT 20,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    profile_type TEXT,
    user_id UUID,
    full_name TEXT,
    phone TEXT,
    country TEXT,
    city TEXT,
    position TEXT,
    organization TEXT,
    avatar_url TEXT,
    bio TEXT,
    is_verified BOOLEAN,
    last_seen TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ap.profile_type,
        ap.user_id,
        ap.full_name,
        ap.phone,
        ap.country,
        ap.city,
        ap.position,
        ap.organization,
        ap.avatar_url,
        ap.bio,
        ap.is_verified,
        ap.last_seen,
        ap.created_at,
        ap.updated_at
    FROM all_profiles ap
    WHERE 
        (search_query = '' OR 
         ap.full_name ILIKE '%' || search_query || '%' OR
         ap.organization ILIKE '%' || search_query || '%' OR
         ap.position ILIKE '%' || search_query || '%' OR
         ap.bio ILIKE '%' || search_query || '%')
        AND ap.profile_type = ANY(profile_types)
        AND (country_filter IS NULL OR ap.country = country_filter)
        AND (NOT verified_only OR ap.is_verified = true)
    ORDER BY 
        ap.is_verified DESC,
        ap.created_at DESC
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get footballers for scout evaluation
CREATE OR REPLACE FUNCTION get_footballers_for_evaluation(
    scout_user_id UUID DEFAULT auth.uid(),
    search_query TEXT DEFAULT '',
    position_filter TEXT DEFAULT NULL,
    country_filter TEXT DEFAULT NULL,
    verified_only BOOLEAN DEFAULT FALSE,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    user_id UUID,
    full_name TEXT,
    position TEXT,
    nationality TEXT,
    current_club TEXT,
    avatar_url TEXT,
    bio TEXT,
    is_verified BOOLEAN,
    age INTEGER,
    experience_level TEXT,
    xp_points INTEGER,
    last_evaluation_date DATE
) AS $$
BEGIN
    -- Check if the requesting user is a scout
    IF NOT user_has_role(scout_user_id, 'scout') THEN
        RAISE EXCEPTION 'Access denied: User is not a scout';
    END IF;
    
    RETURN QUERY
    SELECT 
        fp.user_id,
        fp.full_name,
        fp.position,
        fp.nationality,
        fp.current_club,
        fp.avatar_url,
        fp.bio,
        fp.is_verified,
        CASE 
            WHEN fp.date_of_birth IS NOT NULL 
            THEN EXTRACT(YEAR FROM AGE(fp.date_of_birth))::INTEGER
            ELSE NULL
        END as age,
        fp.experience_level,
        fp.xp_points,
        (
            SELECT MAX(se.evaluation_date)
            FROM scout_evaluations se
            WHERE se.player_id = fp.user_id AND se.scout_id = scout_user_id
        ) as last_evaluation_date
    FROM footballer_profiles fp
    WHERE 
        (search_query = '' OR 
         fp.full_name ILIKE '%' || search_query || '%' OR
         fp.current_club ILIKE '%' || search_query || '%' OR
         fp.position ILIKE '%' || search_query || '%')
        AND (position_filter IS NULL OR fp.position = position_filter)
        AND (country_filter IS NULL OR fp.nationality = country_filter)
        AND (NOT verified_only OR fp.is_verified = true)
    ORDER BY 
        fp.is_verified DESC,
        fp.xp_points DESC,
        fp.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update last_seen timestamp
CREATE OR REPLACE FUNCTION update_user_last_seen(target_user_id UUID DEFAULT auth.uid())
RETURNS VOID AS $$
DECLARE
    primary_role TEXT;
BEGIN
    SELECT get_user_primary_role(target_user_id) INTO primary_role;
    
    CASE primary_role
        WHEN 'footballer' THEN
            UPDATE footballer_profiles 
            SET last_seen = NOW() 
            WHERE user_id = target_user_id;
        WHEN 'scout' THEN
            UPDATE scout_profiles 
            SET last_seen = NOW() 
            WHERE user_id = target_user_id;
        WHEN 'club' THEN
            UPDATE club_profiles 
            SET last_seen = NOW() 
            WHERE user_id = target_user_id;
        WHEN 'fan' THEN
            UPDATE fan_profiles 
            SET last_seen = NOW() 
            WHERE user_id = target_user_id;
    END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_user_primary_role(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_has_role(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION search_profiles(TEXT, TEXT[], TEXT, BOOLEAN, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_footballers_for_evaluation(UUID, TEXT, TEXT, TEXT, BOOLEAN, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_last_seen(UUID) TO authenticated;

-- Comments for documentation
COMMENT ON TABLE user_roles IS 'Tracks user roles and types in the system';
COMMENT ON FUNCTION get_user_primary_role(UUID) IS 'Returns the primary role of a user';
COMMENT ON FUNCTION user_has_role(UUID, TEXT) IS 'Checks if a user has a specific role';
COMMENT ON FUNCTION get_user_profile(UUID) IS 'Returns complete profile information based on user role';
COMMENT ON FUNCTION search_profiles(TEXT, TEXT[], TEXT, BOOLEAN, INTEGER, INTEGER) IS 'Searches across all profile types with filters';
COMMENT ON FUNCTION get_footballers_for_evaluation(UUID, TEXT, TEXT, TEXT, BOOLEAN, INTEGER) IS 'Returns footballers available for scout evaluation';
COMMENT ON FUNCTION update_user_last_seen(UUID) IS 'Updates the last_seen timestamp for a user profile';
