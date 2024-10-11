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
    const { data, error } = await supabase
      .from("profiles")
      .update(profileData)
      .eq("id", userId)
      .select();

    if (error) {
      console.error("Update Error:", error.message);
      return null;
    } else {
      console.log("Update Success:", data);
      return data;
    }
  } catch (error) {
    console.error("Error:", error);
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
    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({
        email: email,
        password: password,
      });

    if (signInError) {
      console.error("Sign In Error:", signInError.message);
      return null;
    }

    if (!signInData.user) {
      console.error("No user data after sign in");
      return null;
    }

    // Step 2: Update the profile
    const { data: updateData, error: updateError } = await supabase
      .from("profiles")
      .update(profileData)
      .eq("id", signInData.user.id)
      .select();

    if (updateError) {
      console.error("Update Error:", updateError.message);
      return null;
    }

    console.log("Update Success:", updateData);
    return updateData;
  } catch (error) {
    console.error("Error:", error);
    return null;
  } finally {
    // Step 3: Sign out the user
    await supabase.auth.signOut();
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
    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({
        email: email,
        password: password,
      });

    if (signInError) {
      throw new Error(`Sign in error: ${signInError.message}`);
    }

    if (!signInData.user) {
      throw new Error("No user data after sign in");
    }

    // Step 2: Update the target user's profile
    const { data: updateData, error: updateError } = await supabase
      .from("profiles")
      .update(profileData)
      .eq("id", targetUserId)
      .select();

    if (updateError) {
      throw new Error(`Update error: ${updateError.message}`);
    }

    console.log("Update Success:", updateData);
    return updateData;
  } catch (error) {
    if (error instanceof Error) {
      console.error("Error:", error.message);
    } else {
      console.error("Unknown error:", error);
    }
    return null;
  } finally {
    // Sign out the user
    await supabase.auth.signOut();
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

  // Example usage of updateOtherUserProfile
  const resultWithOtherLogin = await updateOtherUserProfile(
    email,
    password,
    userId,
    updatedProfileData
  );

  if (resultWithOtherLogin) {
    console.log("Profile updated with other login");
  } else {
    console.log("Profile update with other login failed");
  }
}

if (import.meta.main) {
  main();
}
