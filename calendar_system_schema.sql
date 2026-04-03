-- Create calendar_events table
CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN ('islamic', 'madrasah', 'holiday')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Policy for viewing events
CREATE POLICY "Institutions can view their own calendar events"
    ON calendar_events FOR SELECT
    USING (
        institution_id IN (
            SELECT institution_id FROM profiles WHERE id = auth.uid()
        )
    );

-- Policy for managing events (Admins only)
CREATE POLICY "Admins can manage their own calendar events"
    ON calendar_events FOR ALL
    USING (
        institution_id IN (
            SELECT institution_id FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'madrasah_admin')
        )
    );

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_calendar_events_institution_date ON calendar_events(institution_id, event_date);
