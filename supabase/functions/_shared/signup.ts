import { SupabaseClient } from "@supabase/supabase-js";

interface SignUpData {
  email: string;
  password: string;
  full_name?: string;
  username?: string;
}

export async function signUpWithSupabaseClient(
  userData: SignUpData,
  supabase: SupabaseClient
) {
  const { data, error } = await supabase.auth.signUp({
    email: userData.email,
    password: userData.password,
    options: {
      data: {
        full_name: userData.full_name,
        username: userData.username,
      },
    },
  });

  if (error) throw new Error(`Signup Error: ${error.message}`);
  return data;
}
