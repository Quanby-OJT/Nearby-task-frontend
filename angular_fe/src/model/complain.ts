export interface User {
    first_name: string;
    middle_name?: string;
    last_name: string;
    user_role: string;
  }
  
  export interface ActionBy {
    first_name: string;
    middle_name?: string;
    last_name: string;
  }
  
  export interface Report {
    report_id: number;
    reporter: User;
    violator: User;
    reason: string;
    status: boolean;
    created_at: string;
    action_by?: ActionBy;
    images?: string | null;
  }