export interface User {
    first_name: string;
    middle_name?: string;
    last_name: string;
  }
  
  export interface Tasker {
    user: User;
  }
  
  export interface Client {
    user: User;
  }
  
  export interface TaskTaken {
    client: Client;
  }
  
  export interface Feedback {
    tasker: Tasker;
    feedback: string;
    rating: string;
    task_taken: TaskTaken;
    created_at: string;
    reported?: string;
  }