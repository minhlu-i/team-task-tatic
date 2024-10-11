create policy "Team members can upload files"
on "storage"."objects"
as permissive
for insert
to public
with check (((bucket_id = 'team-files'::text) AND (EXISTS ( SELECT 1
   FROM team_members tm
  WHERE ((tm.user_id = auth.uid()) AND (tm.team_id = ((storage.foldername(objects.name))[1])::uuid))))));


create policy "Team members can view files"
on "storage"."objects"
as permissive
for select
to public
using (((bucket_id = 'team-files'::text) AND (EXISTS ( SELECT 1
   FROM team_members tm
  WHERE ((tm.user_id = auth.uid()) AND (tm.team_id = ((storage.foldername(objects.name))[1])::uuid))))));


CREATE TRIGGER prevent_delete_trigger BEFORE DELETE ON storage.objects FOR EACH ROW WHEN ((old.bucket_id = 'team-files'::text)) EXECUTE FUNCTION prevent_update_delete();

CREATE TRIGGER prevent_update_trigger BEFORE UPDATE ON storage.objects FOR EACH ROW WHEN ((old.bucket_id = 'team-files'::text)) EXECUTE FUNCTION prevent_update_delete();


