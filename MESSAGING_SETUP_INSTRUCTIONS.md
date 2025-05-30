# 🔧 **Messaging System Setup Instructions** 💬

## 🎯 **Issue: Message Sending Stuck on Loading**

The ChatScreen shows the empty state correctly, but when you try to send a message, it gets stuck loading. This is because the **messages table doesn't exist** in your Supabase database yet.

## 🛠️ **Quick Fix: Set Up Database Tables**

### **Step 1: Open Supabase Dashboard**
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Open your **El Goat** project
4. Navigate to **SQL Editor** (in the left sidebar)

### **Step 2: Run the Database Setup Script**
1. Click **"New Query"** in the SQL Editor
2. Copy and paste the following SQL script:

```sql
-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
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

-- Enable Row Level Security
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_sender_receiver ON messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- Row Level Security Policies for messages
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

-- Row Level Security Policies for typing_status
CREATE POLICY "Users can view all typing status" ON typing_status
FOR SELECT USING (true);

CREATE POLICY "Users can update their own typing status" ON typing_status
FOR ALL USING (auth.uid() = user_id);

-- Enable realtime for tables
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_status;

-- Grant permissions
GRANT ALL ON messages TO authenticated;
GRANT ALL ON typing_status TO authenticated;
```

### **Step 3: Execute the Script**
1. Click **"Run"** button (or press Ctrl+Enter)
2. Wait for the script to complete
3. You should see "Success. No rows returned" message

### **Step 4: Verify Tables Created**
1. Go to **Table Editor** in the left sidebar
2. You should now see:
   - ✅ **messages** table
   - ✅ **typing_status** table

## 🎉 **Test the Messaging System**

1. **Restart your app** (hot reload)
2. **Navigate to a user profile**
3. **Tap the message button**
4. **Try sending a message** - it should work now!

## 🔍 **Troubleshooting**

### **If you still get errors:**

1. **Check Console Logs**: Look for detailed error messages
2. **Verify Authentication**: Make sure you're logged in
3. **Check Permissions**: Ensure RLS policies are applied correctly

### **Common Error Messages:**

- **"Messages table not found"** → Run the SQL script above
- **"Not authenticated"** → Log in to the app first
- **"Permission denied"** → Check RLS policies in Supabase

## 📱 **Expected Behavior After Setup**

✅ **Message Button Works**: Taps open ChatScreen instantly
✅ **Empty State Shows**: "No messages yet - Start the conversation!"
✅ **Message Sending**: Text messages send and appear immediately
✅ **Real-time Updates**: Messages appear instantly for both users
✅ **Typing Indicators**: Shows when other user is typing

## 🎯 **Next Steps**

Once messaging works, you can enhance it with:
- 📸 **Media Messages**: Images and videos
- 😀 **Emoji Reactions**: React to messages
- 🔍 **Message Search**: Find old messages
- 📱 **Push Notifications**: Real-time alerts

**The messaging system will be fully functional after running the database setup!** 🚀💬
