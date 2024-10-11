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
      return null;
    } else {
      console.log("Login Success:", data);
      return data.user;
    }
  } catch (error) {
    console.error("Error:", error);
    return null;
  }
}

async function createTeam(teamName: string) {
  try {
    const { data, error } = await supabase.rpc("create_team_with_creator", {
      p_team_name: teamName,
    });

    if (error) {
      console.error("Team Creation Error:", error.message);
    } else {
      console.log("Team Created Successfully. Team ID:", data);
    }
  } catch (error) {
    console.error("Error:", error);
  }
}

async function main() {
  const email = "user1@example.com";
  const password = "user1@example.com";

  const user = await checkLogin(email, password);

  if (user) {
    await createTeam("My New Team");
  }
}

if (import.meta.main) {
  main();
}
