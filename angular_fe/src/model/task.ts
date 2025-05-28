export interface User {
  first_name: string;
  middle_name?: string;
  last_name: string;
}

export interface Client {
  client_id?: string;
  user: User;
}

export interface Task {
  task_id: string;
  clients: Client;
  task_title: string;
  specialization: string;
  proposed_price: number;
  location: string;
  urgent: boolean;
  status: string;
  created_at: string;
  action_by: string;
  actionByUser?: {
      first_name: string;
      middle_name?: string;
      last_name: string;
  };
  action_reason?: string;
  task_begin_date: string; 
  task_description: string;
}