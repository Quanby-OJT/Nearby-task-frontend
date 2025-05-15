export interface User {
    first_name: string;
    middle_name?: string;
    last_name: string;
    status: boolean;
  }
  
  export interface Client {
    user: User;
  }
  
  export interface Tasker {
    user: User;
  }
  
  export interface TaskTaken {
    task_taken_id: number;
    clients: Client;
    tasker: Tasker;
    created_at: string;
    task_status: string;
  }
  
  export interface Conversation {
    user: any;
    user_id?: number;
    task_taken: TaskTaken;
    conversation: string;
    reported: boolean;
  }
  
  export interface Message {
    user_id: number;
    user: User;
    conversation: string;
    created_at: string;
  }