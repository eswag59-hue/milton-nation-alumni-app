-- Allow multiple photos per post. media_url (single) is kept for backward
-- compatibility (holds the first image); media_urls is the full ordered list.
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS media_urls text[];
