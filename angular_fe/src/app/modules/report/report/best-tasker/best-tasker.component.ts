import { Component, OnInit } from '@angular/core';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
@Component({
  selector: 'app-best-tasker',
  imports: [CommonModule],
  templateUrl: './best-tasker.component.html',
  styleUrl: './best-tasker.component.css'
})
export class BestTaskerComponent implements OnInit {
  taskers: { userName: string; specialization: string; taskCount: number }[] = [];

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchTaskers();
  }

  fetchTaskers(): void {
    this.reportService.getTopTasker().subscribe({
      next: (response) => {
        if (response.success) {
          this.taskers = response.taskers;
        }
      },
      error: (err) => {
        console.error('Error fetching taskers:', err);
      }
    });
  }
}