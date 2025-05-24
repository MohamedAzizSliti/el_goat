-- Create player_skills table
CREATE TABLE IF NOT EXISTS player_skills (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    technical_skills JSONB DEFAULT '{}',
    physical_attributes JSONB DEFAULT '{}',
    mental_attributes JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Add RLS policies
ALTER TABLE player_skills ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own skills
CREATE POLICY "Users can view their own skills"
    ON player_skills
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy for users to insert their own skills
CREATE POLICY "Users can insert their own skills"
    ON player_skills
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy for users to update their own skills
CREATE POLICY "Users can update their own skills"
    ON player_skills
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Create function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_player_skills_updated_at
    BEFORE UPDATE ON player_skills
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column(); 