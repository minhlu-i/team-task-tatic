

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."task_status" AS ENUM (
    'pending',
    'in_progress',
    'review',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."task_status" OWNER TO "postgres";


CREATE TYPE "public"."team_member_role" AS ENUM (
    'leader',
    'member',
    'admin'
);


ALTER TYPE "public"."team_member_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_task_id" "uuid", "p_message" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, task_id, message)
  VALUES (p_user_id, p_task_id, p_message)
  RETURNING id INTO new_notification_id;
  
  RETURN new_notification_id;
END;
$$;


ALTER FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_task_id" "uuid", "p_message" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_task_attachment"("p_task_id" "uuid", "p_file_path" "text", "p_file_type" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_team_id UUID;
  new_attachment_id UUID;
BEGIN
  -- Lấy team_id của task
  SELECT team_id INTO v_team_id FROM tasks WHERE id = p_task_id;
  
  -- Kiểm tra xem người tạo attachment có phải là thành viên của team không
  IF NOT is_team_member(v_team_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only team members can add attachments to tasks';
  END IF;

  -- Tạo attachment mới
  INSERT INTO task_attachments (task_id, file_path, file_type, uploaded_by)
  VALUES (p_task_id, p_file_path, p_file_type, auth.uid())
  RETURNING id INTO new_attachment_id;

  RETURN new_attachment_id;
END;
$$;


ALTER FUNCTION "public"."create_task_attachment"("p_task_id" "uuid", "p_file_path" "text", "p_file_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_task_comment"("p_task_id" "uuid", "p_comment" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_team_id UUID;
  new_comment_id UUID;
BEGIN
  -- Lấy team_id của task
  SELECT team_id INTO v_team_id FROM tasks WHERE id = p_task_id;
  
  -- Kiểm tra xem người tạo comment có phải là thành viên của team không
  IF NOT is_team_member(v_team_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only team members can comment on tasks';
  END IF;

  -- Tạo comment mới
  INSERT INTO task_comments (task_id, user_id, comment)
  VALUES (p_task_id, auth.uid(), p_comment)
  RETURNING id INTO new_comment_id;

  RETURN new_comment_id;
END;
$$;


ALTER FUNCTION "public"."create_task_comment"("p_task_id" "uuid", "p_comment" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_team_task"("p_team_id" "uuid", "p_title" "text", "p_description" "text", "p_assigned_to" "uuid", "p_due_date" timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_task_id UUID;
BEGIN
  -- Kiểm tra xem người tạo task có phải là thành viên của team không
  IF NOT is_team_member(p_team_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only team members can create tasks';
  END IF;

  -- Kiểm tra xem người được giao task có phải là thành viên của team không
  IF NOT is_team_member(p_team_id, p_assigned_to) THEN
    RAISE EXCEPTION 'Tasks can only be assigned to team members';
  END IF;

  -- Tạo task mới
  INSERT INTO tasks (team_id, title, description, assigned_to, assigned_by, status, due_date)
  VALUES (p_team_id, p_title, p_description, p_assigned_to, auth.uid(), 'pending', p_due_date)
  RETURNING id INTO new_task_id;

  RETURN new_task_id;
END;
$$;


ALTER FUNCTION "public"."create_team_task"("p_team_id" "uuid", "p_title" "text", "p_description" "text", "p_assigned_to" "uuid", "p_due_date" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_team_with_creator"("p_team_name" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_team_id UUID;
BEGIN
  -- Tạo team mới
  INSERT INTO teams (name, creator_id)
  VALUES (p_team_name, auth.uid())
  RETURNING id INTO new_team_id;
  
  -- Thêm creator như là admin của team
  INSERT INTO team_members (team_id, user_id, role)
  VALUES (new_team_id, auth.uid(), 'admin');
  
  RETURN new_team_id;
END;
$$;


ALTER FUNCTION "public"."create_team_with_creator"("p_team_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."invite_team_member"("p_team_id" "uuid", "p_user_email" "text", "p_role" "public"."team_member_role") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Kiểm tra xem người thực hiện hành động có phải là admin không
  IF NOT is_team_admin(p_team_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only team admin can invite members';
  END IF;

  -- Lấy user_id từ email
  SELECT id INTO v_user_id FROM auth.users WHERE email = p_user_email;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User with email % not found', p_user_email;
  END IF;

  -- Thêm member vào team
  INSERT INTO team_members (team_id, user_id, role)
  VALUES (p_team_id, v_user_id, p_role)
  ON CONFLICT (team_id, user_id) DO NOTHING;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."invite_team_member"("p_team_id" "uuid", "p_user_email" "text", "p_role" "public"."team_member_role") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_task_in_team"("p_task_id" "uuid", "p_team_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM tasks
    WHERE id = p_task_id AND team_id = p_team_id
  );
END;
$$;


ALTER FUNCTION "public"."is_task_in_team"("p_task_id" "uuid", "p_team_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_team_admin"("p_team_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = p_team_id AND user_id = p_user_id AND role = 'admin'
  );
END;
$$;


ALTER FUNCTION "public"."is_team_admin"("p_team_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_team_member"("p_team_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = p_team_id AND user_id = p_user_id
  );
END;
$$;


ALTER FUNCTION "public"."is_team_member"("p_team_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remove_team_member"("p_team_id" "uuid", "p_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Kiểm tra xem người thực hiện hành động có phải là admin không
  IF NOT is_team_admin(p_team_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only team admin can remove members';
  END IF;

  -- Xóa member khỏi team
  DELETE FROM team_members
  WHERE team_id = p_team_id AND user_id = p_user_id;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."remove_team_member"("p_team_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_notification_read_status"("p_notification_id" "uuid", "p_is_read" boolean) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  updated BOOLEAN;
BEGIN
  UPDATE notifications
  SET is_read = p_is_read
  WHERE id = p_notification_id AND user_id = auth.uid()
  RETURNING TRUE INTO updated;
  
  RETURN COALESCE(updated, FALSE);
END;
$$;


ALTER FUNCTION "public"."update_notification_read_status"("p_notification_id" "uuid", "p_is_read" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_team_member_role"("p_team_id" "uuid", "p_user_id" "uuid", "p_new_role" "public"."team_member_role") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Kiểm tra xem người thực hiện hành động có phải là admin không
  IF NOT is_team_admin(p_team_id, auth.uid()) THEN
    RAISE EXCEPTION 'Only team admin can update member roles';
  END IF;

  -- Cập nhật role của member
  UPDATE team_members
  SET role = p_new_role
  WHERE team_id = p_team_id AND user_id = p_user_id;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."update_team_member_role"("p_team_id" "uuid", "p_user_id" "uuid", "p_new_role" "public"."team_member_role") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "task_id" "uuid",
    "message" "text" NOT NULL,
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "username" "text",
    "full_name" "text",
    "avatar_url" "text",
    "website" "text",
    CONSTRAINT "username_length" CHECK (("char_length"("username") >= 3))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."task_attachments" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "task_id" "uuid",
    "file_path" "text" NOT NULL,
    "file_type" "text" NOT NULL,
    "uploaded_by" "uuid",
    "uploaded_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."task_attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."task_comments" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "task_id" "uuid",
    "user_id" "uuid",
    "comment" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."task_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "team_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text",
    "assigned_to" "uuid",
    "assigned_by" "uuid",
    "status" "public"."task_status" DEFAULT 'pending'::"public"."task_status" NOT NULL,
    "due_date" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."team_members" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "team_id" "uuid",
    "user_id" "uuid",
    "role" "public"."team_member_role" NOT NULL
);


ALTER TABLE "public"."team_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."teams" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "creator_id" "uuid" NOT NULL
);


ALTER TABLE "public"."teams" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."todos" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "task" "text",
    "is_complete" boolean DEFAULT false,
    "inserted_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "todos_task_check" CHECK (("char_length"("task") > 3))
);


ALTER TABLE "public"."todos" OWNER TO "postgres";


ALTER TABLE "public"."todos" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."todos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."task_attachments"
    ADD CONSTRAINT "task_attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_team_id_user_id_key" UNIQUE ("team_id", "user_id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."todos"
    ADD CONSTRAINT "todos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_attachments"
    ADD CONSTRAINT "task_attachments_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id");



ALTER TABLE ONLY "public"."task_attachments"
    ADD CONSTRAINT "task_attachments_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");



ALTER TABLE ONLY "public"."team_members"
    ADD CONSTRAINT "team_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."todos"
    ADD CONSTRAINT "todos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



CREATE POLICY "Allow select on team_members for team members" ON "public"."team_members" FOR SELECT USING (("auth"."uid"() IN ( SELECT "team_members_1"."user_id"
   FROM "public"."team_members" "team_members_1"
  WHERE ("team_members_1"."team_id" = "team_members_1"."team_id"))));



CREATE POLICY "Authenticated users can create teams" ON "public"."teams" FOR INSERT WITH CHECK (("auth"."uid"() = "creator_id"));



CREATE POLICY "Individuals can create todos." ON "public"."todos" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Individuals can delete their own todos." ON "public"."todos" FOR DELETE USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Individuals can update their own todos." ON "public"."todos" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Individuals can view their own todos. " ON "public"."todos" FOR SELECT USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Only creator can delete team" ON "public"."teams" FOR DELETE USING (("auth"."uid"() = "creator_id"));



CREATE POLICY "Only creator can update team" ON "public"."teams" FOR UPDATE USING (("auth"."uid"() = "creator_id"));



CREATE POLICY "Only uploader can delete their own attachments" ON "public"."task_attachments" FOR DELETE USING ((("auth"."uid"() = "uploaded_by") AND (EXISTS ( SELECT 1
   FROM ("public"."tasks"
     JOIN "public"."team_members" ON (("tasks"."team_id" = "team_members"."team_id")))
  WHERE (("tasks"."id" = "task_attachments"."task_id") AND ("team_members"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Only uploader can update their own attachments" ON "public"."task_attachments" FOR UPDATE USING ((("auth"."uid"() = "uploaded_by") AND (EXISTS ( SELECT 1
   FROM ("public"."tasks"
     JOIN "public"."team_members" ON (("tasks"."team_id" = "team_members"."team_id")))
  WHERE (("tasks"."id" = "task_attachments"."task_id") AND ("team_members"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Prevent direct delete on team_members" ON "public"."team_members" FOR DELETE USING (false);



CREATE POLICY "Prevent direct insert on task_attachments" ON "public"."task_attachments" FOR INSERT WITH CHECK (false);



CREATE POLICY "Prevent direct insert on task_comments" ON "public"."task_comments" FOR INSERT WITH CHECK (false);



CREATE POLICY "Prevent direct insert on tasks" ON "public"."tasks" FOR INSERT WITH CHECK (false);



CREATE POLICY "Prevent direct insert on team_members" ON "public"."team_members" FOR INSERT WITH CHECK (false);



CREATE POLICY "Prevent direct inserts on notifications" ON "public"."notifications" FOR INSERT WITH CHECK (false);



CREATE POLICY "Prevent direct update on team_members" ON "public"."team_members" FOR UPDATE USING (false);



CREATE POLICY "Prevent direct updates on notifications" ON "public"."notifications" FOR UPDATE USING (false);



CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Team members can delete team tasks" ON "public"."tasks" FOR DELETE USING ("public"."is_team_member"("team_id", "auth"."uid"()));



CREATE POLICY "Team members can delete their own comments" ON "public"."task_comments" FOR DELETE USING ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."tasks"
  WHERE (("tasks"."id" = "task_comments"."task_id") AND "public"."is_team_member"("tasks"."team_id", "auth"."uid"()))))));



CREATE POLICY "Team members can update team tasks" ON "public"."tasks" FOR UPDATE USING ("public"."is_team_member"("team_id", "auth"."uid"()));



CREATE POLICY "Team members can update their own comments" ON "public"."task_comments" FOR UPDATE USING ((("auth"."uid"() = "user_id") AND (EXISTS ( SELECT 1
   FROM "public"."tasks"
  WHERE (("tasks"."id" = "task_comments"."task_id") AND "public"."is_team_member"("tasks"."team_id", "auth"."uid"()))))));



CREATE POLICY "Team members can view all task attachments" ON "public"."task_attachments" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."tasks"
     JOIN "public"."team_members" ON (("tasks"."team_id" = "team_members"."team_id")))
  WHERE (("tasks"."id" = "task_attachments"."task_id") AND ("team_members"."user_id" = "auth"."uid"())))));



CREATE POLICY "Team members can view task comments" ON "public"."task_comments" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."tasks"
  WHERE (("tasks"."id" = "task_comments"."task_id") AND "public"."is_team_member"("tasks"."team_id", "auth"."uid"())))));



CREATE POLICY "Team members can view team tasks" ON "public"."tasks" FOR SELECT USING ("public"."is_team_member"("team_id", "auth"."uid"()));



CREATE POLICY "Users can delete their own notifications" ON "public"."notifications" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING ((( SELECT "auth"."uid"() AS "uid") = "id"));



CREATE POLICY "Users can view teams they are a member of" ON "public"."teams" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."team_members"
  WHERE (("team_members"."team_id" = "teams"."id") AND ("team_members"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can view their own notifications" ON "public"."notifications" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_attachments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."team_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."teams" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."todos" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";




















































































































































































GRANT ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_task_id" "uuid", "p_message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_task_id" "uuid", "p_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_notification"("p_user_id" "uuid", "p_task_id" "uuid", "p_message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_task_attachment"("p_task_id" "uuid", "p_file_path" "text", "p_file_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_task_attachment"("p_task_id" "uuid", "p_file_path" "text", "p_file_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_task_attachment"("p_task_id" "uuid", "p_file_path" "text", "p_file_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_task_comment"("p_task_id" "uuid", "p_comment" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_task_comment"("p_task_id" "uuid", "p_comment" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_task_comment"("p_task_id" "uuid", "p_comment" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_team_task"("p_team_id" "uuid", "p_title" "text", "p_description" "text", "p_assigned_to" "uuid", "p_due_date" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_team_task"("p_team_id" "uuid", "p_title" "text", "p_description" "text", "p_assigned_to" "uuid", "p_due_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_team_task"("p_team_id" "uuid", "p_title" "text", "p_description" "text", "p_assigned_to" "uuid", "p_due_date" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_team_with_creator"("p_team_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_team_with_creator"("p_team_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_team_with_creator"("p_team_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."invite_team_member"("p_team_id" "uuid", "p_user_email" "text", "p_role" "public"."team_member_role") TO "anon";
GRANT ALL ON FUNCTION "public"."invite_team_member"("p_team_id" "uuid", "p_user_email" "text", "p_role" "public"."team_member_role") TO "authenticated";
GRANT ALL ON FUNCTION "public"."invite_team_member"("p_team_id" "uuid", "p_user_email" "text", "p_role" "public"."team_member_role") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_task_in_team"("p_task_id" "uuid", "p_team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_task_in_team"("p_task_id" "uuid", "p_team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_task_in_team"("p_task_id" "uuid", "p_team_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_team_admin"("p_team_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_team_admin"("p_team_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_team_admin"("p_team_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_team_member"("p_team_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_team_member"("p_team_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_team_member"("p_team_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_team_member"("p_team_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."remove_team_member"("p_team_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_team_member"("p_team_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_notification_read_status"("p_notification_id" "uuid", "p_is_read" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."update_notification_read_status"("p_notification_id" "uuid", "p_is_read" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_notification_read_status"("p_notification_id" "uuid", "p_is_read" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_team_member_role"("p_team_id" "uuid", "p_user_id" "uuid", "p_new_role" "public"."team_member_role") TO "anon";
GRANT ALL ON FUNCTION "public"."update_team_member_role"("p_team_id" "uuid", "p_user_id" "uuid", "p_new_role" "public"."team_member_role") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_team_member_role"("p_team_id" "uuid", "p_user_id" "uuid", "p_new_role" "public"."team_member_role") TO "service_role";


















GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."task_attachments" TO "anon";
GRANT ALL ON TABLE "public"."task_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."task_attachments" TO "service_role";



GRANT ALL ON TABLE "public"."task_comments" TO "anon";
GRANT ALL ON TABLE "public"."task_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."task_comments" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "anon";
GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."team_members" TO "anon";
GRANT ALL ON TABLE "public"."team_members" TO "authenticated";
GRANT ALL ON TABLE "public"."team_members" TO "service_role";



GRANT ALL ON TABLE "public"."teams" TO "anon";
GRANT ALL ON TABLE "public"."teams" TO "authenticated";
GRANT ALL ON TABLE "public"."teams" TO "service_role";



GRANT ALL ON TABLE "public"."todos" TO "anon";
GRANT ALL ON TABLE "public"."todos" TO "authenticated";
GRANT ALL ON TABLE "public"."todos" TO "service_role";



GRANT ALL ON SEQUENCE "public"."todos_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."todos_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."todos_id_seq" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
