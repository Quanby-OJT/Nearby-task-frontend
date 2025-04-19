import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PaymentService } from 'src/app/services/payment.service';

@Component({
  selector: 'app-payment',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './payment.component.html',
  styleUrls: ['./payment.component.css']
})
export class PaymentComponent implements OnInit {
  paymentLogs: any[] = [];
  filteredPaymentLogs: any[] = [];
  displayPaymentLogs: any[] = [];
  currentSearchText: string = '';
  currentFilterType: string = '';
  logsPerPage: number = 10;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  paginationButtons: (number | string)[] = [];

  constructor(private paymentService: PaymentService) {}

  ngOnInit(): void {
    this.paymentService.getPaymentLogs().subscribe(
      (data) => {
        this.paymentLogs = data;
        this.filteredPaymentLogs = [...data];
        this.updatePage();
      },
      (error) => {
        console.error('Error fetching payment logs', error);
      }
    );
  }

  searchLogs(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  filterLogs(event: Event) {
    this.currentFilterType = (event.target as HTMLSelectElement).value;
    this.applyFilters();
  }

  applyFilters() {
    let tempLogs = [...this.paymentLogs];

    if (this.currentSearchText) {
      const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);
      tempLogs = tempLogs.filter(log => {
        const fullName = log.user_name.toLowerCase();
        return searchTerms.every(term => fullName.includes(term));
      });
    }

    if (this.currentFilterType) {
      tempLogs = tempLogs.filter(log => log.payment_type === this.currentFilterType);
    }

    this.filteredPaymentLogs = tempLogs;
    this.currentPage = 1;
    this.updatePage();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredPaymentLogs.length / this.logsPerPage);
    const start = (this.currentPage - 1) * this.logsPerPage;
    const end = start + this.logsPerPage;
    this.displayPaymentLogs = this.filteredPaymentLogs.slice(start, end);
    this.startIndex = start + 1;
    this.endIndex = Math.min(end, this.filteredPaymentLogs.length);
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

  previousPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.updatePage();
    }
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.updatePage();
    }
  }

  goToPage(page: number | string) {
    if (typeof page === 'number') {
      this.currentPage = page;
      this.updatePage();
    }
  }
}