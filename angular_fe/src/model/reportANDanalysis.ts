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
  }
  
  export interface Client {
    userName: string;
    address: string;
    taskCount: number;
    gender: string;
  }
  
  export interface MonthlyTrends {
    [key: string]: { [month: string]: number };
  }
  
  export interface ChartSeries {
    name: string;
    data: number[];
  }