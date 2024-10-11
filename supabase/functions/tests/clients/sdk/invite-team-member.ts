import { load } from "https://deno.land/std@0.190.0/dotenv/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.26.0";

await load({ export: true });

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseAnonKey = Deno.env.get("SUPABASE_AUTH_ANON_KEY");

if (!supabaseUrl || !supabaseAnonKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
  Deno.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

type TeamMemberRole = "admin" | "member"; // Adjust based on your enum definition

async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    throw error;
  }

  return data.user;
}

async function inviteTeamMember(teamId: string, userEmail: string, role: TeamMemberRole): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .rpc('invite_team_member', {
        p_team_id: teamId,
        p_user_email: userEmail,
        p_role: role
      });

    if (error) {
      throw error;
    }

    console.log("Team member invited successfully");
    return data;
  } catch (error) {
    console.error("Error inviting team member:", error.message);
    return false;
  }
}

async function getTeamMembers(teamId: string) {
  try {
    const { data, error } = await supabase
      .from("team_members")
      .select("*")
      .eq("team_id", teamId);

    if (error) {
      throw error;
    }

    return data;
  } catch (error) {
    console.error("Error fetching team members:", error.message);
    return null;
  }
}

async function main() {
  try {
    const email = "user1@example.com";
    const password = "user1@example.com";
    await signIn(email, password);
    console.log("Signed in successfully");

    // Example usage after authentication
    const teamId = "6ff6f645-6638-4edb-b9a9-94c99a4c030a";
    const userEmailToInvite = "user2@example.com";

    // Invite a new team member
    const invited = await inviteTeamMember(teamId, userEmailToInvite, "member");

    if (invited) {
      console.log("User invited successfully");

      // Get all team members
      const teamMembers = await getTeamMembers(teamId);
      console.log("Team members:", teamMembers);
    } else {
      console.log("Failed to invite user");
    }
  } catch (error) {
    console.error("An error occurred:", error.message);
  } finally {
    // Sign out
    await supabase.auth.signOut();
    console.log("Signed out successfully");
  }
}

if (import.meta.main) {
  main();
}
