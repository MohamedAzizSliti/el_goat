-- Create exercises table for AI-generated training exercises
CREATE TABLE IF NOT EXISTS exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('technical', 'physical', 'tactical', 'mental')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('beginner', 'intermediate', 'advanced', 'professional')),
    target_position TEXT,
    target_skills TEXT[] DEFAULT '{}',
    estimated_duration INTEGER NOT NULL DEFAULT 30, -- in minutes
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'doing', 'done')),
    score INTEGER CHECK (score >= 0 AND score <= 100),
    feedback TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exercises_user_id ON exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_exercises_status ON exercises(status);
CREATE INDEX IF NOT EXISTS idx_exercises_type ON exercises(type);
CREATE INDEX IF NOT EXISTS idx_exercises_difficulty ON exercises(difficulty);
CREATE INDEX IF NOT EXISTS idx_exercises_created_at ON exercises(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_exercises_updated_at 
    BEFORE UPDATE ON exercises 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own exercises" ON exercises
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own exercises" ON exercises
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own exercises" ON exercises
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own exercises" ON exercises
    FOR DELETE USING (auth.uid() = user_id);

-- Create exercise statistics view
CREATE OR REPLACE VIEW exercise_stats AS
SELECT 
    user_id,
    COUNT(*) as total_exercises,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_exercises,
    COUNT(*) FILTER (WHERE status = 'doing') as in_progress_exercises,
    COUNT(*) FILTER (WHERE status = 'done') as completed_exercises,
    ROUND(
        (COUNT(*) FILTER (WHERE status = 'done')::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 
        2
    ) as completion_rate,
    ROUND(AVG(score) FILTER (WHERE score IS NOT NULL), 2) as average_score,
    SUM(estimated_duration) FILTER (WHERE status = 'done') as total_time_spent,
    COUNT(*) FILTER (WHERE type = 'technical') as technical_exercises,
    COUNT(*) FILTER (WHERE type = 'physical') as physical_exercises,
    COUNT(*) FILTER (WHERE type = 'tactical') as tactical_exercises,
    COUNT(*) FILTER (WHERE type = 'mental') as mental_exercises
FROM exercises
GROUP BY user_id;

-- Grant access to the view
GRANT SELECT ON exercise_stats TO authenticated;

-- Create RLS policy for the view
CREATE POLICY "Users can view their own exercise stats" ON exercise_stats
    FOR SELECT USING (auth.uid() = user_id);

-- Create function to get recent exercises
CREATE OR REPLACE FUNCTION get_recent_exercises(days_back INTEGER DEFAULT 7)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    title TEXT,
    description TEXT,
    type TEXT,
    difficulty TEXT,
    status TEXT,
    score INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.user_id,
        e.title,
        e.description,
        e.type,
        e.difficulty,
        e.status,
        e.score,
        e.created_at
    FROM exercises e
    WHERE e.user_id = auth.uid()
    AND e.created_at >= NOW() - INTERVAL '1 day' * days_back
    ORDER BY e.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get exercise progress
CREATE OR REPLACE FUNCTION get_exercise_progress(target_user_id UUID DEFAULT auth.uid())
RETURNS TABLE (
    week_start DATE,
    exercises_completed INTEGER,
    average_score DECIMAL,
    total_time_spent INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE_TRUNC('week', e.completed_at)::DATE as week_start,
        COUNT(*)::INTEGER as exercises_completed,
        ROUND(AVG(e.score), 2) as average_score,
        SUM(e.estimated_duration)::INTEGER as total_time_spent
    FROM exercises e
    WHERE e.user_id = target_user_id
    AND e.status = 'done'
    AND e.completed_at >= NOW() - INTERVAL '12 weeks'
    GROUP BY DATE_TRUNC('week', e.completed_at)
    ORDER BY week_start DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample data for testing (optional)
-- INSERT INTO exercises (user_id, title, description, instructions, type, difficulty, target_skills, estimated_duration) VALUES
-- (auth.uid(), 'Ball Control Drills', 'Improve your first touch and ball control', '1. Set up 5 cones in a line\n2. Dribble through using both feet\n3. Focus on close control\n4. Repeat 10 times', 'technical', 'beginner', ARRAY['Ball Control', 'Dribbling'], 20),
-- (auth.uid(), 'Sprint Training', 'Build speed and acceleration', '1. Warm up for 10 minutes\n2. Sprint 50m at maximum speed\n3. Rest for 2 minutes\n4. Repeat 8 times', 'physical', 'intermediate', ARRAY['Speed', 'Acceleration'], 45),
-- (auth.uid(), 'Tactical Positioning', 'Learn proper positioning for your role', '1. Study formation diagrams\n2. Practice movement patterns\n3. Understand defensive responsibilities\n4. Work on communication', 'tactical', 'advanced', ARRAY['Positioning', 'Communication'], 60);

-- Comments for documentation
COMMENT ON TABLE exercises IS 'AI-generated personalized training exercises for football players';
COMMENT ON COLUMN exercises.type IS 'Type of exercise: technical, physical, tactical, or mental';
COMMENT ON COLUMN exercises.difficulty IS 'Difficulty level: beginner, intermediate, advanced, or professional';
COMMENT ON COLUMN exercises.status IS 'Current status: pending, doing, or done';
COMMENT ON COLUMN exercises.score IS 'Performance score from 0-100 when exercise is completed';
COMMENT ON COLUMN exercises.target_skills IS 'Array of skills this exercise targets for improvement';
COMMENT ON COLUMN exercises.estimated_duration IS 'Estimated time to complete exercise in minutes';
COMMENT ON COLUMN exercises.metadata IS 'Additional AI-generated data and exercise parameters';
