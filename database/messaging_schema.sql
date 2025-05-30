-- Real-time Messaging Database Schema for El Goat App
-- Execute this in your Supabase SQL Editor

-- Enable Row Level Security
ALTER TABLE IF EXISTS messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS typing_status ENABLE ROW LEVEL SECURITY;

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'file', 'audio')),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    reactions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create typing_status table
CREATE TABLE IF NOT EXISTS typing_status (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_sender_receiver ON messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_sender ON messages(receiver_id, sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_typing_status_updated_at ON typing_status(updated_at);

-- Create storage bucket for chat media
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat_media', 'chat_media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for chat_media bucket
CREATE POLICY "Users can upload their own chat media" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'chat_media' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view chat media" ON storage.objects
FOR SELECT USING (bucket_id = 'chat_media');

CREATE POLICY "Users can delete their own chat media" ON storage.objects
FOR DELETE USING (bucket_id = 'chat_media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Row Level Security Policies for messages table
CREATE POLICY "Users can view their own messages" ON messages
FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
);

CREATE POLICY "Users can insert their own messages" ON messages
FOR INSERT WITH CHECK (
    auth.uid() = sender_id
);

CREATE POLICY "Users can update their own messages" ON messages
FOR UPDATE USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
) WITH CHECK (
    auth.uid() = sender_id OR auth.uid() = receiver_id
);

CREATE POLICY "Users can delete their own messages" ON messages
FOR DELETE USING (
    auth.uid() = sender_id
);

-- Row Level Security Policies for typing_status table
CREATE POLICY "Users can view all typing status" ON typing_status
FOR SELECT USING (true);

CREATE POLICY "Users can update their own typing status" ON typing_status
FOR ALL USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at on messages
DROP TRIGGER IF EXISTS update_messages_updated_at ON messages;
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to automatically update updated_at on typing_status
DROP TRIGGER IF EXISTS update_typing_status_updated_at ON typing_status;
CREATE TRIGGER update_typing_status_updated_at
    BEFORE UPDATE ON typing_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to clean up old typing status (optional)
CREATE OR REPLACE FUNCTION cleanup_old_typing_status()
RETURNS void AS $$
BEGIN
    UPDATE typing_status 
    SET is_typing = FALSE 
    WHERE updated_at < NOW() - INTERVAL '30 seconds' AND is_typing = TRUE;
END;
$$ language 'plpgsql';

-- Enable realtime for tables
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_status;

-- Grant necessary permissions
GRANT ALL ON messages TO authenticated;
GRANT ALL ON typing_status TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Create function to get conversation list with user details
CREATE OR REPLACE FUNCTION get_conversations(user_id UUID)
RETURNS TABLE (
    other_user_id UUID,
    last_message TEXT,
    last_message_time TIMESTAMP WITH TIME ZONE,
    unread_count BIGINT,
    other_user_name TEXT,
    other_user_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH conversation_messages AS (
        SELECT 
            CASE 
                WHEN m.sender_id = user_id THEN m.receiver_id
                ELSE m.sender_id
            END as other_id,
            m.content,
            m.created_at,
            m.is_read,
            m.receiver_id,
            ROW_NUMBER() OVER (
                PARTITION BY CASE 
                    WHEN m.sender_id = user_id THEN m.receiver_id
                    ELSE m.sender_id
                END 
                ORDER BY m.created_at DESC
            ) as rn
        FROM messages m
        WHERE m.sender_id = user_id OR m.receiver_id = user_id
    ),
    latest_messages AS (
        SELECT 
            other_id,
            content as last_message,
            created_at as last_message_time
        FROM conversation_messages
        WHERE rn = 1
    ),
    unread_counts AS (
        SELECT 
            CASE 
                WHEN m.sender_id = user_id THEN m.receiver_id
                ELSE m.sender_id
            END as other_id,
            COUNT(*) as unread_count
        FROM messages m
        WHERE m.receiver_id = user_id AND m.is_read = FALSE
        GROUP BY other_id
    )
    SELECT 
        lm.other_id,
        lm.last_message,
        lm.last_message_time,
        COALESCE(uc.unread_count, 0),
        COALESCE(
            fp.full_name,
            sp.full_name,
            cp.club_name,
            'Unknown User'
        ) as other_user_name,
        COALESCE(
            fp.avatar_url,
            sp.avatar_url,
            cp.logo_url,
            'assets/images/default_avatar.png'
        ) as other_user_avatar
    FROM latest_messages lm
    LEFT JOIN unread_counts uc ON lm.other_id = uc.other_id
    LEFT JOIN footballer_profiles fp ON lm.other_id = fp.user_id
    LEFT JOIN scout_profiles sp ON lm.other_id = sp.user_id
    LEFT JOIN club_profiles cp ON lm.other_id = cp.user_id
    ORDER BY lm.last_message_time DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_conversations(UUID) TO authenticated;
