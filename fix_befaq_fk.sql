-- Fix foreign key constraint for befaq_exams to allow cascading deletes
ALTER TABLE public.befaq_exams DROP CONSTRAINT IF EXISTS befaq_exams_marhala_id_fkey;
ALTER TABLE public.befaq_exams ADD CONSTRAINT befaq_exams_marhala_id_fkey FOREIGN KEY (marhala_id) REFERENCES public.classes(id) ON DELETE CASCADE;
