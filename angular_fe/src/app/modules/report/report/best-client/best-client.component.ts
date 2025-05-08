import { Component, OnInit } from '@angular/core';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
import { Client } from '../../../../../model/reportANDanalysis';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: 'app-best-client',
  imports: [CommonModule, AngularSvgIconModule],
  templateUrl: './best-client.component.html',
  styleUrl: './best-client.component.css'
})
export class BestClientComponent implements OnInit {
  clients: Client[] = [];
  filteredClients: Client[] = [];
  displayClients: Client[] = [];
  paginationButtons: (number | string)[] = [];
  clientsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  isLoading: boolean = true;

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchClients();
  }

  fetchClients(): void {
    this.isLoading = true;
    this.reportService.getTopClient().subscribe({
      next: (response) => {
        if (response.success) {
          this.clients = response.clients;
          this.filteredClients = [...this.clients];
          this.updatePage();
        }
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching clients:', err);
        this.isLoading = false;
      }
    });
  }

  searchClients(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  applyFilters() {
    let tempClients = [...this.clients];

    // Apply search filter if there's a search term
    if (this.currentSearchText) {
      tempClients = tempClients.filter(client => {
        const userName = (client.userName || '').toLowerCase();
        const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);
        return searchTerms.every(term => userName.includes(term));
      });
    }

    this.filteredClients = tempClients;
    this.currentPage = 1;
    this.updatePage();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredClients.length / this.clientsPerPage);
    this.displayClients = this.filteredClients.slice(
      (this.currentPage - 1) * this.clientsPerPage,
      this.currentPage * this.clientsPerPage
    );
    this.startIndex = (this.currentPage - 1) * this.clientsPerPage + 1;
    this.endIndex = Math.min(this.currentPage * this.clientsPerPage, this.filteredClients.length);
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

  changeClientsPerPage(event: Event) {
    this.clientsPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
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