import { Component, OnInit } from '@angular/core';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
import { Tasker, TaskHistory } from '../../../../../model/reportANDanalysis';
import { AngularSvgIconModule } from 'angular-svg-icon';
import Swal from 'sweetalert2'; // Import SweetAlert2

@Component({
  selector: 'app-best-tasker',
  imports: [CommonModule, AngularSvgIconModule],
  templateUrl: './best-tasker.component.html',
  styleUrl: './best-tasker.component.css'
})
export class BestTaskerComponent implements OnInit {
  taskers: (Tasker & { taskerId: number })[] = [];
  filteredTaskers: (Tasker & { taskerId: number })[] = [];
  displayTaskers: (Tasker & { taskerId: number })[] = [];
  paginationButtons: (number | string)[] = [];
  taskersPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  isLoading: boolean = true;
  selectedTaskerId: number | null = null;
  selectedTaskerName: string = '';
  taskHistory: TaskHistory[] = [];

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchTaskers();
  }

  fetchTaskers(): void {
    this.isLoading = true;
    this.reportService.getTopTasker().subscribe({
      next: (response) => {
        if (response.success) {
          this.taskers = response.taskers.map((tasker: Tasker) => ({
            ...tasker,
            taskerId: (tasker as any).taskerId || 0
          })) as (Tasker & { taskerId: number })[];
          this.taskers.sort((a, b) => b.rating - a.rating); 
          this.filteredTaskers = [...this.taskers];
          this.updatePage();
        }
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching taskers:', err);
        this.isLoading = false;
      }
    });
  }

  searchTaskers(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  applyFilters() {
    let tempTaskers = [...this.taskers];
    if (this.currentSearchText) {
      tempTaskers = tempTaskers.filter(tasker => {
        const userName = (tasker.userName || '').toLowerCase();
        const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);
        return searchTerms.every(term => userName.includes(term));
      });
    }

    this.filteredTaskers = tempTaskers;
    this.currentPage = 1;
    this.updatePage();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredTaskers.length / this.taskersPerPage);
    this.displayTaskers = this.filteredTaskers.slice(
      (this.currentPage - 1) * this.taskersPerPage,
      this.currentPage * this.taskersPerPage
    );
    this.startIndex = (this.currentPage - 1) * this.taskersPerPage + 1;
    this.endIndex = Math.min(this.currentPage * this.taskersPerPage, this.filteredTaskers.length);
    this.makePaginationButtons();
  }

  makePaginationButtons() {
    const maxButtons = 3;
    let start = Math.max(1, this.currentPage - 1);
    let end = Math.min(this.totalPages, start + maxButtons - 1);

    this.paginationButtons = [];

    for (let i = start; i <= end; i++) {
      this.paginationButtons.push(i);
    }

  }

  changeTaskersPerPage(event: Event) {
    this.taskersPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
    this.currentPage = 1;
    this.updatePage();
  }

  goToPage(page: number | string) {
    const pageNum = typeof page === 'string' ? parseInt(page, 10) : page;
    if (pageNum >= 1 && pageNum <= this.totalPages) {
      this.currentPage = pageNum;
      this.updatePage();
    }
  }

  openTaskHistoryModal(taskerId: number, taskerName: string) {
    this.selectedTaskerId = taskerId;
    this.selectedTaskerName = taskerName;
    this.fetchTaskHistory(taskerId);
  }

  fetchTaskHistory(taskerId: number) {
    this.reportService.getTaskHistory(taskerId).subscribe({
      next: (response) => {
        console.log('Task history response:', response);
        if (response.success) {
          this.taskHistory = response.taskHistory;
          console.log('Assigned task history:', this.taskHistory);

          const tableHtml = `
            <div style="overflow-x: auto; max-height: 400px;">
              <table style="width: 100%; border-collapse: collapse; text-align: left; font-size: 14px;">
                <thead style="border-bottom: 1px solid #ddd;">
                  <tr>
                    <th style="padding: 8px 16px;">Client Name</th>
                    <th style="padding: 8px 16px;">Task Description</th>
                    <th style="padding: 8px 16px;">Status</th>
                    <th style="padding: 8px 16px;">Task Taken Place</th>
                  </tr>
                </thead>
                <tbody>
                  ${this.taskHistory.length > 0
                    ? this.taskHistory.map(task => `
                        <tr style="border-bottom: 1px solid #eee;">
                          <td style="padding: 12px 16px;">${task.clientName}</td>
                          <td style="padding: 12px 16px;">${task.taskDescription}</td>
                          <td style="padding: 12px 16px;">${task.status}</td>
                          <td style="padding: 12px 16px;">${task.address ? `${task.address.barangay}, ${task.address.city}, ${task.address.province}` : 'Empty'}</td>
                        </tr>
                      `).join('')
                    : '<tr><td colspan="4" style="padding: 12px 16px; text-align: center;">No task history available.</td></tr>'
                  }
                </tbody>
              </table>
            </div>
          `;

          Swal.fire({
            title: `Task History for ${this.selectedTaskerName}`,
            html: tableHtml,
            width: '800px',
            showCloseButton: true,
            focusConfirm: false,
            confirmButtonText: 'Close',
            customClass: {
              htmlContainer: 'text-right',
              actions: 'swal2-actions-right'
            },
          });
        }
      },
      error: (err) => {
        console.error('Error fetching task history:', err);
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Failed to load task history. Please try again later.',
          confirmButtonText: 'Close'
        });
      }
    });
  }
}