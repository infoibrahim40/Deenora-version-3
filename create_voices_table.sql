-- Create voices table
CREATE TABLE IF NOT EXISTS voices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    provider_voice_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'approved',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on voices
ALTER TABLE voices ENABLE ROW LEVEL SECURITY;

-- RLS Policies for voices
DROP POLICY IF EXISTS "Institutions can view their own voices" ON voices;
CREATE POLICY "Institutions can view their own voices" ON voices
    FOR SELECT USING (institution_id IN (
        SELECT institution_id FROM profiles WHERE id = auth.uid()
    ));

DROP POLICY IF EXISTS "Institutions can insert their own voices" ON voices;
CREATE POLICY "Institutions can insert their own voices" ON voices
    FOR INSERT WITH CHECK (institution_id IN (
        SELECT institution_id FROM profiles WHERE id = auth.uid()
    ));

-- Update voice_broadcasts to use voice_id instead of voice_template_id
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'voice_broadcasts' AND column_name = 'voice_id') THEN
        ALTER TABLE voice_broadcasts ADD COLUMN voice_id UUID REFERENCES voices(id) ON DELETE CASCADE;
    END IF;
END $$;
