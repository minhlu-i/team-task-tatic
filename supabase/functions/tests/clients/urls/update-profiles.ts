import { load } from "dotenv";

await load({ export: true });

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseAnonKey = Deno.env.get("SUPABASE_AUTH_ANON_KEY") || "";

if (!supabaseUrl || !supabaseAnonKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  Deno.exit(1);
}

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
    const response = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${userId}`,
      {
        method: "PATCH",
        headers: {
          apikey: supabaseAnonKey,
          "Content-Type": "application/json",
          Prefer: "return=representation",
        },
        body: JSON.stringify(profileData),
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    console.log("Update Success:", data);
    return data;
  } catch (error) {
    console.error("Update Error:", error);
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
    const signInResponse = await fetch(
      `${supabaseUrl}/auth/v1/token?grant_type=password`,
      {
        method: "POST",
        headers: {
          apikey: supabaseAnonKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      }
    );

    if (!signInResponse.ok) {
      throw new Error(`HTTP error! status: ${signInResponse.status}`);
    }

    const signInData = await signInResponse.json();
    const accessToken = signInData.access_token;
    const userId = signInData.user.id;

    // Step 2: Update the profile
    const updateResponse = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${userId}`,
      {
        method: "PATCH",
        headers: {
          apikey: supabaseAnonKey,
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
          Prefer: "return=representation",
        },
        body: JSON.stringify(profileData),
      }
    );

    if (!updateResponse.ok) {
      throw new Error(`HTTP error! status: ${updateResponse.status}`);
    }

    const data = await updateResponse.json();
    console.log("Update Success:", data);
    return data;
  } catch (error) {
    console.error("Error:", error);
    return null;
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
    const signInResponse = await fetch(
      `${supabaseUrl}/auth/v1/token?grant_type=password`,
      {
        method: "POST",
        headers: {
          apikey: supabaseAnonKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      }
    );

    if (!signInResponse.ok) {
      throw new Error(`HTTP error! status: ${signInResponse.status}`);
    }

    const signInData = await signInResponse.json();
    const accessToken = signInData.access_token;

    // Step 2: Update the target user's profile
    const updateResponse = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${targetUserId}`,
      {
        method: "PATCH",
        headers: {
          apikey: supabaseAnonKey,
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
          Prefer: "return=representation",
        },
        body: JSON.stringify(profileData),
      }
    );

    if (!updateResponse.ok) {
      throw new Error(`HTTP error! status: ${updateResponse.status}`);
    }

    const data = await updateResponse.json();
    console.log("Update Success:", data);
    return data;
  } catch (error) {
    console.error("Error:", error);
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
  if (resultWithOtherLogin) {
    console.log("Other user's profile updated");
  } else {
    console.log("Other user's profile update failed");
  }
}

if (import.meta.main) {
  main();
}
