-- ─────────────────────────────────────────────────────────────────────────────
-- Migration 003: Storage bucket & RLS policies for trade screenshots
-- Run this in the Supabase SQL editor OR via `supabase db push`
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Create the bucket (safe to re-run, ignored if it already exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('trade-screenshots', 'trade-screenshots', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Allow authenticated users to UPLOAD files inside the `trades/` folder
CREATE POLICY "Authenticated users can upload screenshots"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'trade-screenshots'
  AND (storage.foldername(name))[1] = 'trades'
);

-- 3. Allow users to UPDATE (upsert) their own files
CREATE POLICY "Users can update their own screenshots"
ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'trade-screenshots')
WITH CHECK (bucket_id = 'trade-screenshots');

-- 4. Allow anyone to READ (view) screenshots (bucket is public)
CREATE POLICY "Public read access to screenshots"
ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'trade-screenshots');

-- 5. Allow authenticated users to DELETE their own files
CREATE POLICY "Users can delete their own screenshots"
ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'trade-screenshots');
