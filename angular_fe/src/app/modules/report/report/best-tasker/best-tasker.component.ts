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
  filteredTaskers: { userName: string; specialization: string; taskCount: number }[] = [];
  displayTaskers: { userName: string; specialization: string; taskCount: number }[] = [];
  paginationButtons: (number | string)[] = [];
  taskersPerPage: number = 10;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchTaskers();
  }

  fetchTaskers(): void {
    this.reportService.getTopTasker().subscribe({
      next: (response) => {
        if (response.success) {
          this.taskers = response.taskers;
          this.filteredTaskers = [...this.taskers];
          this.updatePage();
        }
      },
      error: (err) => {
        console.error('Error fetching taskers:', err);
      }
    });
  }

  searchTaskers(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  applyFilters() {
    let tempTaskers = [...this.taskers];

    // Apply search filter if there's a search term
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
}