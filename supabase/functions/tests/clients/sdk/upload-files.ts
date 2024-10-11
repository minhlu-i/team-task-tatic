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

async function uploadFile(filePath: string, bucket: string, folderPath: string = "") {
  try {
    const file = await Deno.readFile(filePath);
    const fileName = filePath.split("/").pop();

    if (!fileName) {
      throw new Error("Invalid file path");
    }

    const fullPath = folderPath ? `${folderPath}/${fileName}` : fileName;

    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(fullPath, file, {
        cacheControl: "3600",
        upsert: false
      });

    if (error) {
      throw error;
    }

    console.log("File uploaded successfully:", data.path);
    return data.path;
  } catch (error) {
    console.error("Error uploading file:", error.message);
    return null;
  }
}

function getPublicUrl(bucket: string, filePath: string) {
  const { data } = supabase.storage.from(bucket).getPublicUrl(filePath);
  return data.publicUrl;
}

async function listFiles(bucket: string, folderPath: string = "") {
  const { data, error } = await supabase.storage
    .from(bucket)
    .list(folderPath);

  if (error) {
    console.error("Error listing files:", error.message);
    return null;
  }

  return data;
}

async function deleteFile(bucket: string, filePath: string) {
  const { data, error } = await supabase.storage
    .from(bucket)
    .remove([filePath]);

  console.log(`🚀 ~ deleteFile ~ data:`, data)

  if (error) {
    console.error("Error deleting file:", error.message);
    return false;
  }

  console.log("File deleted successfully");
  return true;
}

async function main() {
  const bucket = "avatars"; // Replace with your actual bucket name
  const folderPath = ""; // Optional: specify a folder path in your bucket

  // Example: Upload a file
  const filePath = "supabase/functions/tests/clients/sdk/files/example.txt";
  const uploadedPath = await uploadFile(filePath, bucket, folderPath);

  if (uploadedPath) {
    // Get public URL of the uploaded file
    const publicUrl = getPublicUrl(bucket, uploadedPath);
    console.log("Public URL:", publicUrl);

    // List files in the bucket/folder
    const files = await listFiles(bucket, folderPath);
    console.log("Files in bucket:", files);

    // Delete the uploaded file
    await deleteFile(bucket, uploadedPath);
  }
}

if (import.meta.main) {
  main();
}
