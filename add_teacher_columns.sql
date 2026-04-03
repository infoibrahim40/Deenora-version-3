ALTER TABLE teachers ADD COLUMN IF NOT EXISTS pin TEXT;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{"can_manage_attendance": false, "can_manage_results": false, "allowed_classes": []}'::jsonb;
