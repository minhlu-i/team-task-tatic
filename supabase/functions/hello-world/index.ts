import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { handleCors, addCorsHeaders } from '../_shared/cors.ts';

serve((req: Request) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Your function logic here
  const data = {
    message: 'Hello from function-one!'
  };

  // Create response and add CORS headers
  const response = new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  });

  return addCorsHeaders(response);
});
