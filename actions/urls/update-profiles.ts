import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  process.exit(1);
}

const axiosInstance = axios.create({
  baseURL: supabaseUrl,
  headers: {
    apikey: supabaseAnonKey,
    "Content-Type": "application/json",
  },
});

interface ProfileUpdateData {
  username?: string;
  full_name?: string;
  avatar_url?: string;
  website?: string;
}

async function updateProfileWithoutLogin(
  userId: string,
  profileData: ProfileUpdateData
) {
  try {
    const response = await axiosInstance.patch(
      `/rest/v1/profiles?id=eq.${userId}`,
      profileData,
      {
        headers: {
          Prefer: "return=representation",
        },
      }
    );

    console.log("Update Success:", response.data);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error("Update Error:", error.response?.data);
    } else {
      console.error("Error:", error);
    }
    return null;
  }
}

async function updateProfileWithLogin(
  email: string,
  password: string,
  profileData: ProfileUpdateData
) {
  try {
    // Step 1: Sign in the user
    const signInResponse = await axiosInstance.post(
      "/auth/v1/token?grant_type=password",
      {
        email,
        password,
      }
    );

    const accessToken = signInResponse.data.access_token;
    const userId = signInResponse.data.user.id;

    // Step 2: Update the profile
    const updateResponse = await axiosInstance.patch(
      `/rest/v1/profiles?id=eq.${userId}`,
      profileData,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Prefer: "return=representation",
        },
      }
    );

    console.log("Update Success:", updateResponse.data);
    return updateResponse.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error("Error:", error.response?.data);
    } else {
      console.error("Error:", error);
    }
    return null;
  } finally {
    // Step 3: Sign out the user (Note: Supabase doesn't have a specific logout endpoint)
    // The client should discard the access token
  }
}

async function updateOtherUserProfile(
  email: string,
  password: string,
  targetUserId: string,
  profileData: ProfileUpdateData
) {
  try {
    // Step 1: Sign in the user
    const signInResponse = await axiosInstance.post(
      "/auth/v1/token?grant_type=password",
      {
        email: email,
        password: password,
      }
    );

    const accessToken = signInResponse.data.access_token;

    // Step 2: Update the target user's profile
    const updateResponse = await axiosInstance.patch(
      `/rest/v1/profiles?id=eq.${targetUserId}`,
      profileData,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Prefer: "return=representation",
        },
      }
    );

    console.log("Update Success:", updateResponse.data);
    return updateResponse.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error("Error:", error.response?.data);
    } else {
      console.error("Error:", error);
    }
    return null;
  }
}

async function main() {
  // Example usage of updateProfileWithoutLogin
  const userId = "94b75ac2-902d-4cc9-88c8-f2f2291137c5";
  const updatedProfileData: ProfileUpdateData = {
    username: "new_username",
    full_name: "New Full Name",
    avatar_url: "https://example.com/new-avatar.jpg",
    website: "https://newwebsite.com",
  };

  const resultWithoutLogin = await updateProfileWithoutLogin(
    userId,
    updatedProfileData
  );
  if (resultWithoutLogin) {
    console.log("Profile updated without login");
  } else {
    console.log("Profile update without login failed");
  }

  // Example usage of updateProfileWithLogin
  const email = "user1@example.com";
  const password = "user1@example.com";

  const resultWithLogin = await updateProfileWithLogin(
    email,
    password,
    updatedProfileData
  );
  if (resultWithLogin) {
    console.log("Profile updated with login");
  } else {
    console.log("Profile update with login failed");
  }

  const resultWithOtherLogin = await updateOtherUserProfile(
    email,
    password,
    userId,
    updatedProfileData
  );
  if (resultWithLogin) {
    console.log("Profile updated with login");
  } else {
    console.log("Profile update with login failed");
  }
}

main();
