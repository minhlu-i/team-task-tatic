import { load } from "dotenv";

await load({ export: true });

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_AUTH_ANON_KEY');

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('Error: SUPABASE_URL or SUPABASE_AUTH_ANON_KEY is not defined in the environment variables.');
  console.log('Available environment variables:', Deno.env.toObject());
  Deno.exit(1);
}

interface SignUpData {
  email: string;
  password: string;
  full_name?: string;
  username?: string;
}

async function signUpWithAPI(userData: SignUpData) {
  try {
    const url = `${SUPABASE_URL}/auth/v1/signup`;
    const headers = {
      "Content-Type": "application/json",
      "apikey": SUPABASE_ANON_KEY as string,
    };
    const body = JSON.stringify(userData);

    console.log('Request URL:', url);
    console.log('Request Headers:', headers);
    console.log('Request Body:', body);

    const response = await fetch(url, {
      method: 'POST',
      headers: headers,
      body: body,
    });

    console.log('Response Status:', response.status);
    console.log('Response Headers:', Object.fromEntries(response.headers));

    const responseText = await response.text();
    console.log('Response Body:', responseText);

    if (!response.ok) {
      let errorMessage = `HTTP error! status: ${response.status}`;
      try {
        const errorData = JSON.parse(responseText);
        if (errorData.msg) {
          errorMessage += ` - ${errorData.msg}`;
        }
      } catch (e) {
        console.error('Failed to parse error response:', e);
      }
      throw new Error(errorMessage);
    }

    const data = JSON.parse(responseText);
    console.log("Signup successful:", data);
    return data;
  } catch (error) {
    if (error instanceof Error) {
      console.error("Signup Error:", error.message);
    } else {
      console.error("Error:", error);
    }
    return null;
  }
}

const newUser: SignUpData = {
  email: "quangminhx10@gmail.com",
  password: "quangminhx10@gmail.com",
  full_name: "Minh Lu",
  username: "Minh Lu",
};

await signUpWithAPI(newUser);
