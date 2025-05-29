-- Create scout_evaluations table for scout player evaluations
CREATE TABLE IF NOT EXISTS scout_evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scout_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic evaluation info
    evaluation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    match_context TEXT, -- e.g., "League match vs Team X", "Training session", etc.
    player_position TEXT NOT NULL,
    
    -- Technical Skills (1-10 scale)
    ball_control INTEGER CHECK (ball_control >= 1 AND ball_control <= 10),
    passing_accuracy INTEGER CHECK (passing_accuracy >= 1 AND passing_accuracy <= 10),
    shooting_ability INTEGER CHECK (shooting_ability >= 1 AND shooting_ability <= 10),
    dribbling_skills INTEGER CHECK (dribbling_skills >= 1 AND dribbling_skills <= 10),
    crossing_ability INTEGER CHECK (crossing_ability >= 1 AND crossing_ability <= 10),
    heading_ability INTEGER CHECK (heading_ability >= 1 AND heading_ability <= 10),
    
    -- Physical Attributes (1-10 scale)
    speed INTEGER CHECK (speed >= 1 AND speed <= 10),
    stamina INTEGER CHECK (stamina >= 1 AND stamina <= 10),
    strength INTEGER CHECK (strength >= 1 AND strength <= 10),
    agility INTEGER CHECK (agility >= 1 AND agility <= 10),
    jumping_ability INTEGER CHECK (jumping_ability >= 1 AND jumping_ability <= 10),
    
    -- Mental Attributes (1-10 scale)
    decision_making INTEGER CHECK (decision_making >= 1 AND decision_making <= 10),
    positioning INTEGER CHECK (positioning >= 1 AND positioning <= 10),
    communication INTEGER CHECK (communication >= 1 AND communication <= 10),
    leadership INTEGER CHECK (leadership >= 1 AND leadership <= 10),
    work_rate INTEGER CHECK (work_rate >= 1 AND work_rate <= 10),
    attitude INTEGER CHECK (attitude >= 1 AND attitude <= 10),
    
    -- Overall Assessment
    overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 10),
    potential_rating INTEGER CHECK (potential_rating >= 1 AND potential_rating <= 10),
    
    -- Recommendations
    recommendation TEXT CHECK (recommendation IN ('highly_recommend', 'recommend', 'consider', 'not_recommend')),
    strengths TEXT,
    areas_for_improvement TEXT,
    additional_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure scout can't evaluate same player multiple times on same date
    UNIQUE(scout_id, player_id, evaluation_date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_scout_evaluations_scout_id ON scout_evaluations(scout_id);
CREATE INDEX IF NOT EXISTS idx_scout_evaluations_player_id ON scout_evaluations(player_id);
CREATE INDEX IF NOT EXISTS idx_scout_evaluations_date ON scout_evaluations(evaluation_date);
CREATE INDEX IF NOT EXISTS idx_scout_evaluations_overall_rating ON scout_evaluations(overall_rating);
CREATE INDEX IF NOT EXISTS idx_scout_evaluations_recommendation ON scout_evaluations(recommendation);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_scout_evaluations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_scout_evaluations_updated_at 
    BEFORE UPDATE ON scout_evaluations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_scout_evaluations_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE scout_evaluations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Scouts can view and manage their own evaluations
CREATE POLICY "Scouts can view their own evaluations" ON scout_evaluations
    FOR SELECT USING (auth.uid() = scout_id);

CREATE POLICY "Scouts can insert their own evaluations" ON scout_evaluations
    FOR INSERT WITH CHECK (auth.uid() = scout_id);

CREATE POLICY "Scouts can update their own evaluations" ON scout_evaluations
    FOR UPDATE USING (auth.uid() = scout_id);

CREATE POLICY "Scouts can delete their own evaluations" ON scout_evaluations
    FOR DELETE USING (auth.uid() = scout_id);

-- Players can view evaluations about them
CREATE POLICY "Players can view evaluations about them" ON scout_evaluations
    FOR SELECT USING (auth.uid() = player_id);

-- Create view for evaluation statistics
CREATE OR REPLACE VIEW scout_evaluation_stats AS
SELECT 
    player_id,
    COUNT(*) as total_evaluations,
    ROUND(AVG(overall_rating), 2) as avg_overall_rating,
    ROUND(AVG(potential_rating), 2) as avg_potential_rating,
    ROUND(AVG(ball_control), 2) as avg_ball_control,
    ROUND(AVG(passing_accuracy), 2) as avg_passing_accuracy,
    ROUND(AVG(shooting_ability), 2) as avg_shooting_ability,
    ROUND(AVG(speed), 2) as avg_speed,
    ROUND(AVG(stamina), 2) as avg_stamina,
    ROUND(AVG(decision_making), 2) as avg_decision_making,
    COUNT(*) FILTER (WHERE recommendation = 'highly_recommend') as highly_recommended_count,
    COUNT(*) FILTER (WHERE recommendation = 'recommend') as recommended_count,
    COUNT(*) FILTER (WHERE recommendation = 'consider') as consider_count,
    COUNT(*) FILTER (WHERE recommendation = 'not_recommend') as not_recommended_count,
    MAX(evaluation_date) as latest_evaluation_date
FROM scout_evaluations
GROUP BY player_id;

-- Grant access to the view
GRANT SELECT ON scout_evaluation_stats TO authenticated;

-- Create RLS policy for the view
CREATE POLICY "Users can view evaluation stats for players" ON scout_evaluation_stats
    FOR SELECT USING (true); -- Allow all authenticated users to view stats

-- Comments for documentation
COMMENT ON TABLE scout_evaluations IS 'Scout evaluations of football players with detailed ratings and recommendations';
COMMENT ON COLUMN scout_evaluations.recommendation IS 'Scout recommendation: highly_recommend, recommend, consider, or not_recommend';
COMMENT ON COLUMN scout_evaluations.overall_rating IS 'Overall player rating from 1-10';
COMMENT ON COLUMN scout_evaluations.potential_rating IS 'Player potential rating from 1-10';
