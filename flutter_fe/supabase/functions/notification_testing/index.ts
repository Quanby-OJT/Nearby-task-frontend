// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.
// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js";
import { create } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
console.log("Hello from Functions po ito!");
const supabaseUrl='https://tzdthgosmoqepbypqbbu.supabase.co'
const supabaseAnonKey='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6ZHRoZ29zbW9xZXBieXBxYmJ1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczOTM2MDM1MiwiZXhwIjoyMDU0OTM2MzUyfQ.erUIxabteQhWPYv2zWQzhLQtR3nO-Bl6RsMF4d8Rx4s'

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error("Missing required environment variables: SUPABASE_URL and SUPABASE_ANON_KEY");
}
const supabase = createClient(supabaseUrl, supabaseAnonKey);
Deno.serve(async (req)=>{
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
  };
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    const { record } = await req.json();
    // Validate required fields
    if (!record?.user_id) {
      return new Response(JSON.stringify({
        error: "Missing user_id in notification record"
      }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders
        }
      });
    }
    // Get user's FCM token
    const { data: userData, error } = await supabase.from('user').select('fcm_token').eq('user_id', record.user_id).single();
    if (error) {
      console.error('Database error:', error);
      return new Response(JSON.stringify({
        error: error.message
      }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders
        }
      });
    }
    if (!userData?.fcm_token) {
      return new Response(JSON.stringify({
        error: "User not found or FCM token missing"
      }), {
        status: 404,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders
        }
      });
    }
    const fcm_token = userData.fcm_token;
    // Get service account credentials from environment variables
    const clientEmail = Deno.env.get('CLIENT_EMAIL');
    const privateKey = Deno.env.get('PRIVATE_KEY');
    const projectId = Deno.env.get('PROJECT_ID');
    if (!clientEmail || !privateKey || !projectId) {
      console.error('Missing Firebase service account environment variables');
      return new Response(JSON.stringify({
        error: "Missing Firebase service account configuration. Please set FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY, and FIREBASE_PROJECT_ID environment variables."
      }), {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders
        }
      });
    }
    // Get access token
    const accessToken = await getAccessToken(clientEmail, privateKey);
    // Send FCM notification using the v1 API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const fcmPayload = {
      message: {
        token: fcm_token,
        notification: {
          title: 'New Notification',
          body: record.message || 'You have a new update'
        },
        data: {
          notification_id: record.id,
          created_at: record.created_at
        }
      }
    };
    const res = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(fcmPayload)
    });
    const responseData = await res.json();
    if (!res.ok) {
      console.error('Failed to send notification:', responseData);
      throw new Error(responseData.error?.message || 'Failed to send notification');
    }
    console.log('Notification sent successfully:', responseData);
    return new Response(JSON.stringify({
      success: true,
      message: 'Notification sent successfully',
      fcm_response: responseData
    }), {
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders
      }
    });
  } catch (err) {
    console.error('Function error:', err);
    return new Response(JSON.stringify({
      error: err instanceof Error ? err.message : 'Unknown error occurred'
    }), {
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders
      },
      status: 500
    });
  }
});
async function getAccessToken(clientEmail, privateKey) {
  try {
    const header = {
      alg: "RS256",
      typ: "JWT"
    };
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: clientEmail,
      sub: clientEmail,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: "https://www.googleapis.com/auth/firebase.messaging"
    };
    // Clean and format the private key
    const cleanPrivateKey = privateKey.replace(/\\n/g, '\n').replace(/-----BEGIN PRIVATE KEY-----/, '').replace(/-----END PRIVATE KEY-----/, '').trim();
    const formattedKey = `-----BEGIN PRIVATE KEY-----\n${cleanPrivateKey}\n-----END PRIVATE KEY-----`;
    // Create JWT
    const jwt = await create(header, payload, formattedKey);
    // Exchange JWT for access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt
      })
    });
    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      throw new Error(`Token request failed: ${tokenResponse.status} - ${errorText}`);
    }
    const tokenData = await tokenResponse.json();
    if (!tokenData.access_token) {
      throw new Error("No access token received from Google OAuth");
    }
    return tokenData.access_token;
  } catch (error) {
    console.error('Access token generation error:', error);
    throw new Error(`Failed to generate access token: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}
