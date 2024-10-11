import { SupabaseClient } from "@supabase/supabase-js";

interface ProfileUpdateData {
  username?: string;
  full_name?: string;
  avatar_url?: string;
  website?: string;
}

export async function updateProfileWithoutLogin(
  userId: string,
  profileData: ProfileUpdateData,
  supabase: SupabaseClient
) {
  const { data, error } = await supabase
    .from("profiles")
    .update(profileData)
    .eq("id", userId)
    .select();

  if (error) throw new Error(`Profile Update Error: ${error.message}`);

  return data;
}
