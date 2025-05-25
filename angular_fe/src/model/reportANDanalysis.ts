export interface SpecializationRank {
  specialization: string;
  total_requested: number;
  total_applied: number;
}

export interface Depositor {
  userName: string;
  amount: number;
  month: string;
}

export interface Tasker {
  userName: string;
  specialization: string;
  taskCount: number;
  rating: number;
}

export interface Client {
  userName: string;
  address: string;
  taskCount: number;
  gender: string;
  rating: number;
  clientId: number; // Added for client history
}

export interface MonthlyTrends {
  [key: string]: { [month: string]: number };
}

export interface ChartSeries {
  name: string;
  data: number[];
}

export interface TaskHistory {
  clientName: string;
  taskDescription: string;
  status: string;
  clientAddress: string;
}

export interface ClientHistory {
  taskerName: string;
  taskDescription: string;
  status: string;
  address: {
    barangay: string;
    city: string;
    province: string;
  };
}