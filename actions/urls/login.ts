import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  process.exit(1);
}

async function loginWithAPI(email: string, password: string) {
  try {
    const response = await axios.post(
      `${SUPABASE_URL}/auth/v1/token?grant_type=password`,
      {
        email,
        password,
      },
      {
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_ANON_KEY,
        },
      }
    );

    console.log("Login success:", response.data);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) {
      console.error("Login Error:", error.response.data);
    } else {
      console.error("Error:", error);
    }
    return null;
  }
}

const email = "user1@example.com";
const password = "user1@example.com";

loginWithAPI(email, password);
