import { Component, OnInit } from '@angular/core';
import { CommonModule, NgFor } from '@angular/common';
import { TaskService } from 'src/app/services/task.service';

interface TaskTableData {
  client: string;
  tasker: string;
  ending_in: string;
  status: string;
}

@Component({
  selector: '[nft-auctions-table]',
  templateUrl: './nft-auctions-table.component.html',
  imports: [NgFor, CommonModule],
  standalone: true
})
export class NftAuctionsTableComponent implements OnInit {
  public taskTableData: TaskTableData[] = [];
  public isLoading: boolean = true; // Initialize loading state

  constructor(private taskService: TaskService) {}

  ngOnInit(): void {
    this.fetchTasks();
  }

  private fetchTasks(): void {
    this.isLoading = true; 
    this.taskService.getTasks().subscribe({
      next: (response) => {
        this.taskTableData = this.mapTasksToTableData(response.tasks);
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching tasks:', err);
        this.isLoading = false; 
      }
    });
  }

  private mapTasksToTableData(tasks: any[]): TaskTableData[] {
    return tasks.map(task => {
      const clientName = `${task.clients.user.first_name} ${task.clients.user.middle_name ? task.clients.user.middle_name + ' ' : ''}${task.clients.user.last_name}`;
      const tasker = task.task_title; // Mapping task_title to "Job Title"
      const ending_in = task.task_begin_date; // Mapping task_begin_date to "Date Posted"
      const status = task.status;
      return { client: clientName, tasker, ending_in, status };
    });
  }
}