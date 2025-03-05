export interface task_taken {
  id: number;
  client: string;
  tasker: string;
  task_id: number;
  ending_in?: string;
  status: string;
}
