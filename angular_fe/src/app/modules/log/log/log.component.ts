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
  // List of all logs from the backend
  logs: any[] = [];
  // Logs after search or filter is applied
  filteredLogs: any[] = [];
  // Logs shown on the current page
  displayLogs: any[] = [];
  // Buttons for pagination (numbers or '...')
  paginationButtons: (number | string)[] = [];
  // How many logs to show per page
  logsPerPage: number = 10;
  // Current page number
  currentPage: number = 1;
  // Total number of pages
  totalPages: number = 1;
  // Start and end numbers for the "1 - 10 of 50" display
  startIndex: number = 1;
  endIndex: number = 0;

  // Subscription to fetch logs (we’ll clean it up when the component is destroyed)
  private logsSubscription!: Subscription;

  constructor(private userlogService: UserLogService) {}

  // Runs when the component starts
  ngOnInit(): void {
    // Get logs from the service
    this.logsSubscription = this.userlogService.getUserLogs().subscribe(
      (logs) => {
        // Save the logs and set up the initial display
        this.logs = logs;
        this.filteredLogs = [...logs]; // Copy all logs to filteredLogs
        this.updatePage(); // Show the first page
      },
      (error) => {
        console.error("Error getting logs:", error);
      }
    );
  }

  // Runs when the component is destroyed to prevent memory leaks
  ngOnDestroy(): void {
    if (this.logsSubscription) {
      this.logsSubscription.unsubscribe();
    }
  }

  // Search logs by name when typing in the search box
  searchLogs(event: Event) {
    const searchText = (event.target as HTMLInputElement).value.toLowerCase();
    // Keep logs where the name matches the search text
    this.filteredLogs = this.logs.filter(log =>
      log.user.first_name.toLowerCase().includes(searchText) ||
      (log.user.middle_name && log.user.middle_name.toLowerCase().includes(searchText)) ||
      log.user.last_name.toLowerCase().includes(searchText)
    );
    this.currentPage = 1; // Go back to page 1
    this.updatePage();
  }

  // Filter logs by status (Online/Offline) from the dropdown
  filterLogs(event: Event) {
    const statusValue = (event.target as HTMLSelectElement).value;
    if (statusValue === "") {
      // Show all logs if "All Status" is selected
      this.filteredLogs = [...this.logs];
    } else {
      // Show logs matching the selected status
      this.filteredLogs = this.logs.filter(log => {
        const isOnline = log.user.status ? "active" : "disabled";
        return isOnline === statusValue;
      });
    }
    this.currentPage = 1; // Go back to page 1
    this.updatePage();
  }

  // Update what logs to show on the current page
  updatePage() {
    // Calculate total pages
    this.totalPages = Math.ceil(this.filteredLogs.length / this.logsPerPage);
    // Get logs for the current page
    this.displayLogs = this.filteredLogs.slice(
      (this.currentPage - 1) * this.logsPerPage,
      this.currentPage * this.logsPerPage
    );
    // Set the range for "1 - 10 of 50"
    this.startIndex = (this.currentPage - 1) * this.logsPerPage + 1;
    this.endIndex = Math.min(this.currentPage * this.logsPerPage, this.filteredLogs.length);
    // Update pagination buttons
    this.makePaginationButtons();
  }

  // Create the pagination buttons (e.g., 1, 2, 3, ...)
  makePaginationButtons() {
    const maxButtons = 3; // Show up to 3 page buttons at a time
    let start = Math.max(1, this.currentPage - 1);
    let end = Math.min(this.totalPages, start + maxButtons - 1);

    this.paginationButtons = [];

    // Add page 1 and '...' if needed
    if (start > 1) {
      this.paginationButtons.push(1);
      if (start > 2) {
        this.paginationButtons.push('...');
      }
    }

    // Add page numbers
    for (let i = start; i <= end; i++) {
      this.paginationButtons.push(i);
    }

    // Add last page and '...' if needed
    if (end < this.totalPages) {
      if (end < this.totalPages - 1) {
        this.paginationButtons.push('...');
      }
      this.paginationButtons.push(this.totalPages);
    }
  }

  // Change how many logs to show per page
  changeLogsPerPage(event: Event) {
    this.logsPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
    this.currentPage = 1; // Go back to page 1
    this.updatePage();
  }

  // Go to a specific page when clicking a button
  goToPage(page: number | string) {
    const pageNum = typeof page === 'string' ? parseInt(page, 10) : page;
    if (pageNum >= 1 && pageNum <= this.totalPages) {
      this.currentPage = pageNum;
      this.updatePage();
    }
  }
}