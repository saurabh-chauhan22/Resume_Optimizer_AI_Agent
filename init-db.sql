-- Initialize database for Resume Optimization Assistant

CREATE TABLE IF NOT EXISTS resume_conversations (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    conversation_id VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message_type VARCHAR(50) DEFAULT 'continuing'
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_conversation_id ON resume_conversations(conversation_id);
CREATE INDEX IF NOT EXISTS idx_user_id ON resume_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_timestamp ON resume_conversations(timestamp);

-- Insert a test record to verify table creation
INSERT INTO resume_conversations (user_id, conversation_id, message, ai_response, message_type) 
VALUES ('test_user', 'test_conv', 'Test message', 'Test response', 'new_conversation')
ON CONFLICT DO NOTHING;