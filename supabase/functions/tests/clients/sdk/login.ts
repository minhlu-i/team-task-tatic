import { load } from "dotenv";

import { createClient } from "@supabase/supabase-js";

await load({ export: true });

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseKey = Deno.env.get("SUPABASE_AUTH_ANON_KEY");

if (!supabaseUrl || !supabaseKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  Deno.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkLogin(email: string, password: string) {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      console.error("Login Error:", error.message);
    } else {
      console.log("Login Success:", data);
    }
  } catch (error) {
    console.error("Error:", error);
  }
}

async function main() {
  const email = "user1@example.com";
  const password = "user1@example.com";

  await checkLogin(email, password);
}

if (import.meta.main) {
  main();
}
