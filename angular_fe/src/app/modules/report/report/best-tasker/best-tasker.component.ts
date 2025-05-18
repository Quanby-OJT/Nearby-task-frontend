import { Component, OnInit } from '@angular/core';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
import { Tasker } from '../../../../../model/reportANDanalysis';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: 'app-best-tasker',
  imports: [CommonModule, AngularSvgIconModule],
  templateUrl: './best-tasker.component.html',
  styleUrl: './best-tasker.component.css'
})
export class BestTaskerComponent implements OnInit {
  taskers: Tasker[] = [];
  filteredTaskers: Tasker[] = [];
  displayTaskers: Tasker[] = [];
  paginationButtons: (number | string)[] = [];
  taskersPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  isLoading: boolean = true;

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchTaskers();
  }

  fetchTaskers(): void {
    this.isLoading = true;
    this.reportService.getTopTasker().subscribe({
      next: (response) => {
        if (response.success) {
          this.taskers = response.taskers;
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