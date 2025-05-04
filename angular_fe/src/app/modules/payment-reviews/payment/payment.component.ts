import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PaymentService } from 'src/app/services/payment.service';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: 'app-payment',
  standalone: true,
  imports: [CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './payment.component.html',
  styleUrls: ['./payment.component.css']
})
export class PaymentComponent implements OnInit {
  paymentLogs: any[] = [];
  filteredPaymentLogs: any[] = [];
  displayPaymentLogs: any[] = [];
  currentSearchText: string = '';
  currentFilterType: string = '';
  logsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  paginationButtons: (number | string)[] = [];
  placeholderRows: any[] = [];
  sortDirection: 'asc' | 'desc' | 'default' = 'default';
  amountSortDirection: 'default' | 'highToLow' | 'lowToHigh' = 'default';

  constructor(private paymentService: PaymentService) {}

  ngOnInit(): void {
    this.paymentService.getPaymentLogs().subscribe(
      (data) => {
        console.log('Fetched payment logs:', data);
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
        const fullName = log.user_name?.toLowerCase() || '';
        return searchTerms.every(term => fullName.includes(term));
      });
    }

    if (this.currentFilterType) {
      tempLogs = tempLogs.filter(log => log.payment_type === this.currentFilterType);
    }

    // Apply sorting
    tempLogs.sort((a, b) => {
      // Amount sorting takes precedence
      if (this.amountSortDirection === 'highToLow') {
        return (b.amount || 0) - (a.amount || 0); // Highest to lowest
      } else if (this.amountSortDirection === 'lowToHigh') {
        return (a.amount || 0) - (b.amount || 0); // Lowest to highest
      }

      // Name sorting if amount is default
      if (this.sortDirection === 'asc') {
        return (a.user_name || '').localeCompare(b.user_name || ''); // A-Z
      } else if (this.sortDirection === 'desc') {
        return (b.user_name || '').localeCompare(a.user_name || ''); // Z-A
      }

      // Default: sort by deposit_date (newest to oldest)
      const dateA = new Date(a.deposit_date || '1970-01-01').getTime();
      const dateB = new Date(b.deposit_date || '1970-01-01').getTime();
      return dateB - dateA;
    });

    // Log sorted logs for debugging
    console.log(`Sorted payment logs (amount: ${this.amountSortDirection}, name: ${this.sortDirection}):`, tempLogs.map(log => ({
      user_name: log.user_name,
      amount: log.amount,
      payment_type: log.payment_type,
      deposit_date: log.deposit_date
    })));

    this.filteredPaymentLogs = tempLogs;
    this.currentPage = 1;
    this.updatePage();
  }

  toggleSort() {
    console.log('toggleSort called, current sortDirection:', this.sortDirection); // Debug: Confirm method is called
    this.sortDirection = this.sortDirection === 'default' ? 'asc' :
                         this.sortDirection === 'asc' ? 'desc' : 'default';
    this.amountSortDirection = 'default'; // Reset amount sorting when name sorting is toggled
    this.applyFilters();
  }

  toggleAmountSort() {
    console.log('toggleAmountSort called, current amountSortDirection:', this.amountSortDirection); // Debug: Confirm method is called
    this.amountSortDirection = this.amountSortDirection === 'default' ? 'highToLow' :
                              this.amountSortDirection === 'highToLow' ? 'lowToHigh' : 'default';
    this.sortDirection = 'default'; // Reset name sorting when amount sorting is toggled
    this.applyFilters();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredPaymentLogs.length / this.logsPerPage);
    const start = (this.currentPage - 1) * this.logsPerPage;
    const end = start + this.logsPerPage;
    this.displayPaymentLogs = this.filteredPaymentLogs.slice(start, end);
    this.startIndex = start + 1;
    this.endIndex = Math.min(end, this.filteredPaymentLogs.length);
    
    // Calculate the number of empty rows based on logsPerPage
    const placeholderCount = this.logsPerPage - this.displayPaymentLogs.length;
    this.placeholderRows = Array(placeholderCount).fill({});
    
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

  exportCSV() {
    const headers = ['No', 'User Name', 'Amount', 'Payment Type', 'Created At', 'Deposit Date'];
    const rows = this.displayPaymentLogs.map((log, index) => {
      const row = [
        (this.currentPage - 1) * this.logsPerPage + index + 1,
        `"${log.user_name || ''}"`,
        log.amount || 0,
        `"${log.payment_type || ''}"`,
        `"${log.created_at || ''}"`,
        `"${log.deposit_date || ''}"`
      ];
      console.log('CSV Row:', row);
      return row;
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'PaymentReviews.csv');
  }

  exportPDF() {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });

    try {
      doc.addImage('./assets/icons/heroicons/outline/NearbTask.png', 'PNG', 0, 25, 40, 40); 
    } catch (e) {
      console.error('Failed to load NearbyTasks.png:', e);
    }

    try {
      doc.addImage('./assets/icons/heroicons/outline/Quanby.png', 'PNG', 125, 23, 40, 40);
    } catch (e) {
      console.error('Failed to load Quanby.png:', e);
    }

    // Add title
    const title = 'Payment Reviews';
    doc.setFontSize(20);
    doc.text(title, 170, 52);

    const columns = ['No', 'User Name', 'Amount', 'Payment Type', 'Created At', 'Deposit Date'];
    const rows = this.displayPaymentLogs.map((log, index) => [
      (this.currentPage - 1) * this.logsPerPage + index + 1,
      log.user_name || '',
      log.amount || 0,
      log.payment_type || '',
      log.created_at || '',
      log.deposit_date || ''
    ]);
    autoTable(doc, {
      startY: 100,
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('PaymentReviews.pdf');
  }
}