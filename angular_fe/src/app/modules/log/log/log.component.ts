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
  Math = Math;
  logs: any[] = []; 
  filteredLogs: any[] = []; 
  displayLogs: any[] = []; 
  paginationButton: (number | string)[] = []; 
  logsPerPage: number = 10; 
  currentPage: number = 1; 
  totalPages: number = 1;

  private logsSubscription!: Subscription;

  constructor(private userlogService: UserLogService) {}

  ngOnInit(): void {
    this.logsSubscription = this.userlogService.getUserLogs().subscribe(
      (logs) => {
        console.log("Logs from backend:", logs); 
        this.logs = logs;
        this.filteredLogs = [...logs]; 
        this.updatePagination();
      },
      (error) => {
        console.error("Error fetching logs:", error);
      }
    );
  }

  ngOnDestroy(): void {
    if (this.logsSubscription) {
      this.logsSubscription.unsubscribe();
    }
  }

  searchLogs(event: Event) {
    const searchValue = (event.target as HTMLInputElement).value.toLowerCase();
    this.filteredLogs = this.logs.filter(logs => 
      logs.user.first_name.toLowerCase().includes(searchValue) ||
      (logs.user.middle_name && logs.user.middle_name.toLowerCase().includes(searchValue)) || 
      logs.user.last_name.toLowerCase().includes(searchValue)
    );
    this.currentPage = 1;
    this.updatePagination();
  }
  
  filterLogs(event: Event) {
    const selectedValue = (event.target as HTMLSelectElement).value;
    this.filteredLogs = selectedValue === ""
      ? this.logs
      : this.logs.filter(log => {
          const status = log.user.status ? "active" : "disabled";
          return status === selectedValue;
        });
    this.currentPage = 1;
    this.updatePagination();
  }

  updatePagination() {
    this.totalPages = Math.ceil(this.filteredLogs.length / this.logsPerPage);
    this.displayLogs = this.filteredLogs.slice(
      (this.currentPage - 1) * this.logsPerPage,
      this.currentPage * this.logsPerPage
    );
    this.generatePagination();
  }


  generatePagination() {
    let maxPagesToShow = 3; 
    let startPage = Math.max(1, this.currentPage - 1);
    let endPage = Math.min(this.totalPages, startPage + maxPagesToShow - 1);

    this.paginationButton = [];


    if (startPage > 1) {
      this.paginationButton.push(1);
      if (startPage > 2) {
        this.paginationButton.push('...');
      }
    }


    for (let i = startPage; i <= endPage; i++) {
      this.paginationButton.push(i);
    }

   
    if (endPage < this.totalPages) {
      if (endPage < this.totalPages - 1) {
        this.paginationButton.push('...');
      }
      this.paginationButton.push(this.totalPages);
    }
  }

 
  changeLogsPerPage(event: Event) {
    this.logsPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
    this.currentPage = 1;
    this.updatePagination();
  }

 
  goToPage(page: number | string) {
    const pageNumber = typeof page === 'string' ? parseInt(page, 10) : page;
    if (pageNumber >= 1 && pageNumber <= this.totalPages) {
      this.currentPage = pageNumber;
      this.updatePagination();
    }
  }
}