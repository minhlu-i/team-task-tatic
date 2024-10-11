import { load } from "dotenv";

import { createClient } from "@supabase/supabase-js";

await load({ export: true });

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseAnonKey = Deno.env.get("SUPABASE_AUTH_ANON_KEY");

if (!supabaseUrl || !supabaseAnonKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  Deno.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

interface SignUpData {
  email: string;
  password: string;
  full_name?: string;
  username?: string;
}

async function signUpWithSupabaseClient(userData: SignUpData) {
  try {
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

    if (error) {
      console.error("Signup Error:", error.message);
    } else {
      console.log("Signup Success:", data);
    }
  } catch (error) {
    console.error("Error:", error);
  }
}

async function main() {
  const newUser: SignUpData = {
    email: "new_user@teapot.com",
    password: "securepassword123",
    full_name: "Nguyen Van A",
    username: "nguyenvana",
  };

  await signUpWithSupabaseClient(newUser);
}

if (import.meta.main) {
  main();
}
