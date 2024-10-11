import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

export async function login(
  email: string,
  password: string,
  supabase: ReturnType<typeof createClient>
) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) throw new Error(`Login Error: ${error.message}`);

  return data;
}
