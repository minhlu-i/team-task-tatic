import dotenv from "dotenv";

import { createClient } from "@supabase/supabase-js";

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  process.exit(1);
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

const newUser: SignUpData = {
  email: "new_user@teapot.com",
  password: "securepassword123",
  full_name: "Nguyen Van A",
  username: "nguyenvana",
};

signUpWithSupabaseClient(newUser);
