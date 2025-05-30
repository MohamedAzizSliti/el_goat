-- QUICK FIX: Add missing columns to messages table
-- This script is safe to run multiple times

-- Add missing columns to messages table if they don't exist
DO $$ 
BEGIN
    -- Add message_type column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'message_type'
    ) THEN
        ALTER TABLE messages ADD COLUMN message_type VARCHAR(20) DEFAULT 'text';
        RAISE NOTICE 'Added message_type column';
    ELSE
        RAISE NOTICE 'message_type column already exists';
    END IF;

    -- Add is_read column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'is_read'
    ) THEN
        ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added is_read column';
    ELSE
        RAISE NOTICE 'is_read column already exists';
    END IF;

    -- Add read_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'read_at'
    ) THEN
        ALTER TABLE messages ADD COLUMN read_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added read_at column';
    ELSE
        RAISE NOTICE 'read_at column already exists';
    END IF;

    -- Add reactions column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'reactions'
    ) THEN
        ALTER TABLE messages ADD COLUMN reactions JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added reactions column';
    ELSE
        RAISE NOTICE 'reactions column already exists';
    END IF;

    -- Add updated_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE messages ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column';
    ELSE
        RAISE NOTICE 'updated_at column already exists';
    END IF;
END $$;

-- Create typing_status table if it doesn't exist
CREATE TABLE IF NOT EXISTS typing_status (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (safe to run multiple times)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;

-- Create indexes (safe to run multiple times)
CREATE INDEX IF NOT EXISTS idx_messages_sender_receiver ON messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read) WHERE is_read = FALSE;

-- Show final table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'messages' 
ORDER BY ordinal_position;
