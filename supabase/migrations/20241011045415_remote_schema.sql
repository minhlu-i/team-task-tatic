set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.notify_new_invitation()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  PERFORM pg_notify(
    'new_notification',
    json_build_object(
      'user_id', NEW.user_id,
      'message', NEW.message,
      'data', NEW.data
    )::text
  );
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_task_attachment(p_task_id uuid, p_file_path text, p_file_type text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.create_task_comment(p_task_id uuid, p_comment text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.create_team_task(p_team_id uuid, p_title text, p_description text, p_assigned_to uuid, p_due_date timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.create_team_with_creator(p_team_name text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.invite_team_member(p_team_id uuid, p_user_email text, p_role team_member_role)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_team_name TEXT;
  v_creator_id UUID;
BEGIN
  -- Kiểm tra xem người thực hiện hành động có phải là creator của team không
  SELECT creator_id INTO v_creator_id FROM teams WHERE id = p_team_id;
  IF v_creator_id != auth.uid() THEN
    RAISE EXCEPTION 'Only team creator can invite members';
  END IF;

  -- Lấy user_id từ email
  SELECT id INTO v_user_id FROM auth.users WHERE email = p_user_email;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User with email % not found', p_user_email;
  END IF;

  -- Lấy tên team
  SELECT name INTO v_team_name FROM teams WHERE id = p_team_id;

  -- Thêm member vào team
  INSERT INTO team_members (team_id, user_id, role)
  VALUES (p_team_id, v_user_id, p_role)
  ON CONFLICT (team_id, user_id) DO NOTHING;

  -- Tạo thông báo
  INSERT INTO notifications (user_id, message, data)
  VALUES (v_user_id, 'You have been invited to join team ' || v_team_name, 
          jsonb_build_object('team_id', p_team_id, 'team_name', v_team_name, 'inviter_id', auth.uid(), 'role', p_role));

  RETURN TRUE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_task_in_team(p_task_id uuid, p_team_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM tasks
    WHERE id = p_task_id AND team_id = p_team_id
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_team_admin(p_team_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = p_team_id AND user_id = p_user_id AND role = 'admin'
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_team_member(p_team_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM team_members
    WHERE team_id = p_team_id AND user_id = p_user_id
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.remove_team_member(p_team_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.update_team_member_role(p_team_id uuid, p_user_id uuid, p_new_role team_member_role)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE TRIGGER after_insert_notification AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION notify_new_invitation();


