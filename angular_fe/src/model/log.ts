export interface User {
    first_name: string;
    middle_name?: string;
    last_name: string;
    user_role: string;
    status: boolean;
  }
  
  export interface Log {
    user: User;
    logged_in: string;
    logged_out?: string;
    created_at: string;
  }