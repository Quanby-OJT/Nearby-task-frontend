import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { UserLogService } from 'src/app/services/log.service';

@Component({
  selector: 'app-log',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './log.component.html',
  styleUrl: './log.component.css',
})
export class LogComponent implements OnInit, OnDestroy {
  logs: any[] = [];
  filteredLogs: any[] = [];
  displayLogs: any[] = [];
  paginationButtons: (number | string)[] = [];
  logsPerPage: number = 10;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  currentStatusFilter: string = '';

  private logsSubscription!: Subscription;

  constructor(private userlogService: UserLogService) {}

  ngOnInit(): void {
    this.logsSubscription = this.userlogService.getUserLogs().subscribe(
      (logs) => {
        this.logs = logs;
        this.filteredLogs = [...logs];
        this.updatePage();
      },
      (error) => {
        console.error("Error getting logs:", error);
      }
    );
  }

  ngOnDestroy(): void {
    if (this.logsSubscription) {
      this.logsSubscription.unsubscribe();
    }
  }

  searchLogs(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  filterLogs(event: Event) {
    this.currentStatusFilter = (event.target as HTMLSelectElement).value;
    this.applyFilters();
  }

  applyFilters() {
    let tempLogs = [...this.logs];

    // Apply search filter if there's a search term
    if (this.currentSearchText) {
      tempLogs = tempLogs.filter(log => {
        // Ensure all name parts are strings and handle null/undefined
        const firstName = (log.user.first_name || '').toLowerCase();
        const middleName = (log.user.middle_name || '').toLowerCase();
        const lastName = (log.user.last_name || '').toLowerCase();

        // Create full name with proper spacing
        const fullName = [firstName, middleName, lastName]
          .filter(name => name) // Remove empty strings
          .join(' ');

        // Split search terms to allow matching individual words
        const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);

        // Check if all search terms are present in the full name
        return searchTerms.every(term => fullName.includes(term));
      });
    }

    // Apply status filter if a status is selected
    if (this.currentStatusFilter) {
      tempLogs = tempLogs.filter(log => {
        const logStatus = log.user.status ? 'active' : 'disabled';
        return logStatus === this.currentStatusFilter;
      });
    }

    this.filteredLogs = tempLogs;
    this.currentPage = 1;
    this.updatePage();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredLogs.length / this.logsPerPage);
    this.displayLogs = this.filteredLogs.slice(
      (this.currentPage - 1) * this.logsPerPage,
      this.currentPage * this.logsPerPage
    );
    this.startIndex = (this.currentPage - 1) * this.logsPerPage + 1;
    this.endIndex = Math.min(this.currentPage * this.logsPerPage, this.filteredLogs.length);
    this.makePaginationButtons();
  }

  makePaginationButtons() {
    const maxButtons = 3;
    let start = Math.max(1, this.currentPage - 1);
    let end = Math.min(this.totalPages, start + maxButtons - 1);

    this.paginationButtons = [];

    if (start > 1) {
      this.paginationButtons.push(1);
      if (start > 2) {
        this.paginationButtons.push('...');
      }
    }

    for (let i = start; i <= end; i++) {
      this.paginationButtons.push(i);
    }

    if (end < this.totalPages) {
      if (end < this.totalPages - 1) {
        this.paginationButtons.push('...');
      }
      this.paginationButtons.push(this.totalPages);
    }
  }

  changeLogsPerPage(event: Event) {
    this.logsPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
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
}