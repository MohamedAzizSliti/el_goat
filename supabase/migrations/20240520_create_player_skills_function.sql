-- Function to create player_skills table if it doesn't exist
CREATE OR REPLACE FUNCTION create_player_skills_table()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Create the table if it doesn't exist
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

    -- Enable RLS
    ALTER TABLE player_skills ENABLE ROW LEVEL SECURITY;

    -- Create policies if they don't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'player_skills' 
        AND policyname = 'Users can view their own skills'
    ) THEN
        CREATE POLICY "Users can view their own skills"
            ON player_skills
            FOR SELECT
            USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'player_skills' 
        AND policyname = 'Users can insert their own skills'
    ) THEN
        CREATE POLICY "Users can insert their own skills"
            ON player_skills
            FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'player_skills' 
        AND policyname = 'Users can update their own skills'
    ) THEN
        CREATE POLICY "Users can update their own skills"
            ON player_skills
            FOR UPDATE
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
    END IF;

    -- Create or replace the update_updated_at_column function
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ language 'plpgsql';

    -- Create the trigger if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_player_skills_updated_at'
    ) THEN
        CREATE TRIGGER update_player_skills_updated_at
            BEFORE UPDATE ON player_skills
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END;
$$; 