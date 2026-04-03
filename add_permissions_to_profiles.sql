ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{
  "attendance": true,
  "fees": true,
  "results": true,
  "admit_card": true,
  "seat_plan": true,
  "accounting": true,
  "voice_broadcast": true,
  "sms": true
}'::jsonb;
