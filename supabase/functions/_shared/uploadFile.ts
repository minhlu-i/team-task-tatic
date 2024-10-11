import { SupabaseClient } from "@supabase/supabase-js";

/**
 * Upload a file to a given bucket in Supabase Storage
 *   1. Make sure you have created a bucket in Supabase Storage and configured the appropriate permissions.
 *   2. Security: Make sure you have configured the correct permissions in Supabase Storage to prevent unauthorized access.
 * @param {File} file - The file to upload
 * @param {string} bucket - The name of the bucket to upload the file to
 * @param {string} [folder=""] - The path to the folder to upload the file to. Optional if you want to organize the files in folders.
 * @param {SupabaseClient} supabase - The Supabase client instance
 * @returns {Promise<string>} The public URL of the uploaded file
 * @throws {Error} If an error occurs while uploading the file, or if the file public URL cannot be retrieved
 */
export async function uploadFile(
  file: File,
  bucket: string,
  folder: string = "",
  supabase: SupabaseClient
): Promise<string> {
  const fileExt = file.name.split(".").pop();
  const fileName = `${Math.random()
    .toString(36)
    .substring(2)}${Date.now()}.${fileExt}`;
  const filePath = folder ? `${folder}/${fileName}` : fileName;

  // Upload file
  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(filePath, file);

  if (error) throw new Error(error.message);

  // Get file public URL
  const {
    data: { publicUrl },
  } = supabase.storage.from(bucket).getPublicUrl(filePath);

  if (!publicUrl) throw new Error("Failed to get public URL");

  return publicUrl;
}
