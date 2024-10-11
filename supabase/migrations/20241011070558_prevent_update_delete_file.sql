set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.prevent_update_delete()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  RAISE EXCEPTION 'Update and delete operations are not allowed on this bucket.';
END;
$function$
;


