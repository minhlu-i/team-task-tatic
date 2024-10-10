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

/*
Lưu ý quan trọng:

1. Đảm bảo bạn đã tạo một bucket trong Supabase Storage và cấu hình quyền truy cập phù hợp.
2. Trong function `uploadFile`, tham số `bucket` là tên của bucket bạn muốn upload file lên, và `folder` là tùy chọn nếu bạn muốn tổ chức files trong các thư mục.
3. Sau khi upload thành công, function trả về public URL của file. Bạn có thể lưu URL này vào cơ sở dữ liệu để tham chiếu sau này.
4. Bảo mật: Đảm bảo rằng bạn đã cấu hình đúng quyền truy cập trong Supabase Storage để ngăn chặn truy cập trái phép.
*/

async function uploadFile(file: File, bucket: string, folder: string = "") {
  try {
    // Tạo một tên file duy nhất
    const fileExt = file.name.split(".").pop();
    const fileName = `${Math.random()
      .toString(36)
      .substring(2)}${Date.now()}.${fileExt}`;
    const filePath = folder ? `${folder}/${fileName}` : fileName;

    // Upload file
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, file);

    if (error) {
      throw error;
    }

    // Lấy public URL của file
    const {
      data: { publicUrl },
    } = supabase.storage.from(bucket).getPublicUrl(filePath);

    if (!publicUrl) {
      throw new Error("Failed to get public URL");
    }

    return publicUrl;
  } catch (error) {
    console.error("Error uploading file:", error);
    throw error;
  }
}

/*  REACT COMPONENT EXAMPLE

<antArtifact identifier="file-upload-component" type="application/vnd.ant.code" language="typescript" title="React component để upload file">
import React, { useState } from 'react'

const FileUploader: React.FC = () => {
  const [fileUrl, setFileUrl] = useState<string | null>(null)

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    try {
      const url = await uploadFile(file, 'your-bucket-name', 'optional-folder-name')
      setFileUrl(url)
      console.log('File uploaded successfully:', url)
    } catch (error) {
      console.error('Failed to upload file:', error)
    }
  }

  return (
    <div>
      <input type="file" onChange={handleFileUpload} />
      {fileUrl && <img src={fileUrl} alt="Uploaded file" />}
    </div>
  )
}

export default FileUploader
  */
