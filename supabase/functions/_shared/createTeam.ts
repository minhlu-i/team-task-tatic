import { SupabaseClient } from "@supabase/supabase-js";

export async function createTeam(teamName: string, supabase: SupabaseClient) {
  const { data, error } = await supabase.rpc("create_team_with_creator", {
    p_team_name: teamName,
  });

  if (error) throw new Error(`Team Creation Error: ${error.message}`);
  return data;
}
