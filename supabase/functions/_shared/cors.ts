// supabase/functions/_shared/cors.ts

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, X-Client-Info, Content-Type",
};

export function handleCors(req: Request) {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
}

export function addCorsHeaders(res: Response): Response {
  Object.entries(corsHeaders).forEach(([key, value]) => {
    res.headers.set(key, value);
  });
  return res;
}
