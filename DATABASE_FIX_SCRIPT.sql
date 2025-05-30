-- Fix missing columns in messages table
-- Run this in Supabase SQL Editor

-- Add missing columns to messages table if they don't exist
DO $$
BEGIN
    -- Add message_type column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'messages' AND column_name = 'message_type'
    ) THEN
        ALTER TABLE messages ADD COLUMN message_type VARCHAR(20) DEFAULT 'text';
    END IF;

    -- Add is_read column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'messages' AND column_name = 'is_read'
    ) THEN
        ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add read_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'messages' AND column_name = 'read_at'
    ) THEN
        ALTER TABLE messages ADD COLUMN read_at TIMESTAMP WITH TIME ZONE;
    END IF;

    -- Add reactions column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'messages' AND column_name = 'reactions'
    ) THEN
        ALTER TABLE messages ADD COLUMN reactions JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- Add updated_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'messages' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE messages ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Create typing_status table if it doesn't exist
CREATE TABLE IF NOT EXISTS typing_status (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist and recreate them
DROP POLICY IF EXISTS "Users can view their own messages" ON messages;
DROP POLICY IF EXISTS "Users can insert their own messages" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
DROP POLICY IF EXISTS "Users can view all typing status" ON typing_status;
DROP POLICY IF EXISTS "Users can update their own typing status" ON typing_status;

-- Create Row Level Security Policies for messages
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
);

-- Create Row Level Security Policies for typing_status
CREATE POLICY "Users can view all typing status" ON typing_status
FOR SELECT USING (true);

CREATE POLICY "Users can update their own typing status" ON typing_status
FOR ALL USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_sender_receiver ON messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read) WHERE is_read = FALSE;

-- Enable realtime for tables (only if not already added)
DO $$
BEGIN
    -- Add messages table to realtime if not already added
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE messages;
    END IF;

    -- Add typing_status table to realtime if not already added
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'typing_status'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE typing_status;
    END IF;
END $$;

-- Grant permissions
GRANT ALL ON messages TO authenticated;
GRANT ALL ON typing_status TO authenticated;

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'messages'
ORDER BY ordinal_position;
