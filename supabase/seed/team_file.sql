INSERT INTO storage.buckets (id, name)
VALUES ('team-files', 'Team Files')
ON CONFLICT (id) DO NOTHING;
