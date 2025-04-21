export interface Users {
  id?: number;
  user_id: number;
  first_name: string;
  middle_name: string | null;
  last_name: string;
  birthdate: string | null;
  email: string;
  reported: boolean;
  created_at: string;
  updated_at: string;
  image_link: string | null;
  status: boolean;
  verification_token: string | null;
  emailVerified: boolean;
  acc_status: string;
  user_role: string;
  contact: string | null;
  gender: string | null;
  verified: boolean;
}
