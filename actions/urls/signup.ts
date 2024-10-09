import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  process.exit(1);
}

interface SignUpData {
  email: string;
  password: string;
  full_name?: string;
  username?: string;
}

async function signUpWithAPI(userData: SignUpData) {
  try {
    const response = await axios.post(
      `${SUPABASE_URL}/auth/v1/signup`,
      userData,
      {
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_ANON_KEY,
        },
      }
    );

    console.log("Signup successful:", response.data);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) {
      console.error("Signup Error:", error.response.data);
    } else {
      console.error("Error:", error);
    }
    return null;
  }
}

const newUser: SignUpData = {
  email: "quangminhx9@gmail.com",
  password: "quangminhx9@gmail.com",
  full_name: "Minh Lu",
  username: "Minh Lu",
};

signUpWithAPI(newUser);
