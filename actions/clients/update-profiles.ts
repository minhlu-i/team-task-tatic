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

interface ProfileUpdateData {
  username?: string;
  full_name?: string;
  avatar_url?: string;
  website?: string;
}

async function updateProfile(userId: string, profileData: ProfileUpdateData) {
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

async function main() {
  const userId = "94b75ac2-902d-4cc9-88c8-f2f2291137c5";
  const updatedProfileData: ProfileUpdateData = {
    username: "new_username",
    full_name: "New Full Name",
    avatar_url: "https://example.com/new-avatar.jpg",
    website: "https://newwebsite.com",
  };

  const result = await updateProfile(userId, updatedProfileData);
  if (result) {
    console.log("Profile updated");
  } else {
    console.log("Profile update failed");
  }
}

main();
