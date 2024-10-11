import { load } from "dotenv";

await load({ export: true });

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_AUTH_ANON_KEY") || "";

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  Deno.exit(1);
}

async function loginWithAPI(email: string, password: string) {
  try {
    const response = await fetch(
      `${SUPABASE_URL}/auth/v1/token?grant_type=password`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_ANON_KEY,
        },
        body: JSON.stringify({ email, password }),
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    console.log("Login success:", data);
    return data;
  } catch (error) {
    console.error("Login Error:", error);
    return null;
  }
}

async function main() {
  const email = "user1@example.com";
  const password = "user1@example.com";

  await loginWithAPI(email, password);
}

if (import.meta.main) {
  main();
}
