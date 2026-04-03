-- Ensure voice_templates table exists and has all required columns
CREATE TABLE IF NOT EXISTS voice_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    admin_status VARCHAR(20) DEFAULT 'pending',
    provider_status VARCHAR(20) DEFAULT 'pending',
    provider_voice_id VARCHAR(255),
    provider_voice_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- If the table already exists, add missing columns
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'voice_templates' AND column_name = 'created_at') THEN
        ALTER TABLE voice_templates ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'voice_templates' AND column_name = 'file_url') THEN
        ALTER TABLE voice_templates ADD COLUMN file_url TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'voice_templates' AND column_name = 'admin_status') THEN
        ALTER TABLE voice_templates ADD COLUMN admin_status VARCHAR(20) DEFAULT 'pending';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'voice_templates' AND column_name = 'provider_status') THEN
        ALTER TABLE voice_templates ADD COLUMN provider_status VARCHAR(20) DEFAULT 'pending';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'voice_templates' AND column_name = 'provider_voice_id') THEN
        ALTER TABLE voice_templates ADD COLUMN provider_voice_id VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'voice_templates' AND column_name = 'provider_voice_name') THEN
        ALTER TABLE voice_templates ADD COLUMN provider_voice_name VARCHAR(255);
    END IF;
END $$;

-- Enable RLS
ALTER TABLE voice_templates ENABLE ROW LEVEL SECURITY;

-- Re-apply policies
DROP POLICY IF EXISTS "Institutions can view their own voice templates" ON voice_templates;
CREATE POLICY "Institutions can view their own voice templates" ON voice_templates
    FOR SELECT USING (institution_id IN (
        SELECT institution_id FROM profiles WHERE id = auth.uid()
    ));

DROP POLICY IF EXISTS "Institutions can insert their own voice templates" ON voice_templates;
CREATE POLICY "Institutions can insert their own voice templates" ON voice_templates
    FOR INSERT WITH CHECK (institution_id IN (
        SELECT institution_id FROM profiles WHERE id = auth.uid()
    ));

DROP POLICY IF EXISTS "Super Admins can view all voice templates" ON voice_templates;
CREATE POLICY "Super Admins can view all voice templates" ON voice_templates
    FOR SELECT USING (
        public.is_super_admin()
    );

DROP POLICY IF EXISTS "Super Admins can update all voice templates" ON voice_templates;
CREATE POLICY "Super Admins can update all voice templates" ON voice_templates
    FOR UPDATE USING (
        public.is_super_admin()
    );

