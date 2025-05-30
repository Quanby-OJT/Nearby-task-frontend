import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PaymentService } from 'src/app/services/payment.service';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { DepositDetails, PaymentLog, WithdrawalDetails } from 'src/model/payment-review';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-payment',
  standalone: true,
  imports: [CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './payment.component.html',
  styleUrls: ['./payment.component.css']
})
export class PaymentComponent implements OnInit {
  paymentLogs: PaymentLog[] = [];
  filteredPaymentLogs: PaymentLog[] = [];
  displayPaymentLogs: PaymentLog[] = [];
  currentSearchText: string = '';
  currentFilterType: string = '';
  logsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  paginationButtons: (number | string)[] = [];
  placeholderRows: any[] = [];
  isLoading: boolean = true;
  sortDirections: { [key: string]: string } = {
    userName: 'default',
    amount: 'default',
    depositDate: 'default'
  };
  sortColumn: 'userName' | 'amount' | 'depositDate' = 'depositDate';

  constructor(private paymentService: PaymentService) {}

  ngOnInit(): void {
    this.isLoading = true;
    this.paymentService.getPaymentLogs().subscribe(
      (data: PaymentLog[]) => {
        console.log('Fetched payment logs:', data);
        this.paymentLogs = data;
        this.filteredPaymentLogs = [...data];
        this.updatePage();
        this.isLoading = false;
      },
      (error) => {
        console.error('Error fetching payment logs', error);
        this.isLoading = false;
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
      if (this.sortColumn === 'userName') {
        const nameA = (a.user_name || '').toLowerCase();
        const nameB = (b.user_name || '').toLowerCase();
        if (this.sortDirections['userName'] === 'asc' || this.sortDirections['userName'] === 'default') {
          return nameA.localeCompare(nameB); // A-Z
        } else {
          return nameB.localeCompare(nameA); // Z-A
        }
      } else if (this.sortColumn === 'amount') {
        const amountA = parseFloat(a.amount) || 0;
        const amountB = parseFloat(b.amount) || 0;
        if (this.sortDirections['amount'] === 'lowToHigh') {
          return amountA - amountB; // Lowest to highest
        } else {
          return amountB - amountA; // Highest to lowest (default and highToLow)
        }
      } else if (this.sortColumn === 'depositDate') {
        const dateA = new Date(a.transaction_date || '1970-01-01').getTime(); // Fixed: transaction_date
        const dateB = new Date(b.transaction_date || '1970-01-01').getTime(); // Fixed: transaction_date
        if (this.sortDirections['depositDate'] === 'asc') {
          return dateA - dateB; // Oldest to newest
        } else {
          return dateB - dateA; // Newest to oldest (default and desc)
        }
      }
      return 0;
    });

    // Log sorted logs for debugging
    console.log(`Sorted payment logs (column: ${this.sortColumn}, direction: ${this.sortDirections[this.sortColumn]}):`, tempLogs.map(log => ({
      user_name: log.user_name,
      amount: log.amount,
      payment_type: log.payment_type,
      transaction_date: log.transaction_date // Fixed: transaction_date
    })));

    this.filteredPaymentLogs = tempLogs;
    this.currentPage = 1;
    this.updatePage();
  }

  toggleSort(column: 'userName' | 'amount' | 'depositDate') {
    console.log(`toggleSort called for ${column}, current direction: ${this.sortDirections[column]}`);
    if (this.sortColumn !== column) {
      this.sortDirections[this.sortColumn] = 'default'; // Reset previous column
      this.sortColumn = column;
    }
    if (column === 'userName') {
      this.sortDirections[column] = this.sortDirections[column] === 'default' ? 'asc' :
                                   this.sortDirections[column] === 'asc' ? 'desc' : 'default';
    } else if (column === 'amount') {
      this.sortDirections[column] = this.sortDirections[column] === 'default' ? 'highToLow' :
                                   this.sortDirections[column] === 'highToLow' ? 'lowToHigh' : 'default';
    } else if (column === 'depositDate') {
      this.sortDirections[column] = this.sortDirections[column] === 'default' ? 'asc' :
                                   this.sortDirections[column] === 'asc' ? 'desc' : 'default';
    }
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
    const headers = ['No', 'User Name', 'Amount', 'Payment Type', 'Created At', 'Transaction Date']; // Fixed: Transaction Date
    const rows = this.displayPaymentLogs.map((log, index) => {
      const row = [
        (this.currentPage - 1) * this.logsPerPage + index + 1,
        `"${log.user_name || ''}"`,
        log.amount,
        `"${log.payment_type || ''}"`,
        `"${log.created_at || ''}"`,
        `"${log.transaction_date || ''}"` // Fixed: transaction_date
      ];
      console.log('CSV Row:', row);
      return row;
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'PaymentReviews.csv');
  }

  viewTransactionDetail(log: PaymentLog) {
    Swal.fire({
      title: 'Loading...',
      text: 'Fetching transaction details',
      allowOutsideClick: false,
      showConfirmButton: false,
      willOpen: () => Swal.showLoading(),
    });

    this.paymentService.getPaymentDetails(log.payment_id, log.payment_type).subscribe({
      next: (response: any) => {
        Swal.close();

        let html = '';
        const details = response.payment_details;
        //console.log('Payment details:', details);

        if (log.payment_type === 'Client Deposit') {
          const attr = details.attributes;
          let status = ''
          let badgeColor = '';
          let amount = attr.amount / 100;
            const formattedAMount = amount.toFixed(2); // Format amount to 2 decimal places with cents

            switch (attr.status) {
              case 'succeeded':
                status = "Deposited";
                badgeColor = 'bg-green-100 text-green-800';
                break;
              case 'pending':
                status = "Pending";
                badgeColor = 'bg-yellow-100 text-yellow-800';
                break;
              case 'failed':
                status = "Failed";
                badgeColor = 'bg-red-100 text-red-800';
                break;
              case 'canceled':
                status = "Cancelled";
                badgeColor = 'bg-red-100 text-red-800';
                break;
              case 'awaiting_payment_method':
                status = "Invalid Deposit";
                badgeColor = 'bg-red-100 text-red-800';
                break;
              default:
                status = "Unknown Status";
            }

            html = `
            <div class="text-start">
            <strong>Amount:</strong> ₱${formattedAMount}<br>
            <strong>Currency:</strong> ${attr.currency}<br>
            <strong>Status:</strong> <span class="badge uppercase ${badgeColor} py-1 px-2 rounded-full text-xs font-medium text-">${status}</span><br>
            <strong>Description:</strong> ${attr.description || 'N/A'}<br>
            <strong>Created At:</strong> ${new Date(log.created_at).toLocaleString()}<br>
            <strong>Payment Methods Allowed:</strong> ${attr.payment_method_allowed?.join(', ') || 'N/A'}<br>
            </div>
            `;
        } else if (log.payment_type === 'QTask Withdrawal') {
          let status = ''
          let badgeColor = 'bg-gray-100 text-gray-800';

          switch(details.status) {
            case 'succeeded':
              status = "Successully Withdrawn";
              badgeColor = 'bg-green-100 text-green-800';
              break;
            case 'pending':
              status = "Pending";
              badgeColor = 'bg-yellow-100 text-yellow-800';
              break;
            case 'failed':
              status = "Failed to Withdraw";
              badgeColor = 'bg-red-100 text-red-800';
              break;
            case 'canceled':
              status = "Cancelled";
              badgeColor = 'bg-red-100 text-red-800';
              break;
            case 'awaiting_payment_method':
              status = "Invalid Transaction";
              badgeColor = 'bg-red-100 text-red-800';
              break;
            default:
              status = "Unknown Status";
          }
          html = `
          <div class="text-start">
            <strong>Reference ID:</strong> ${details.reference_id}<br>
            <strong>Status:</strong> <span class="badge uppercase ${badgeColor} py-1 px-2 rounded-full text-xs font-medium text-">${status}</span><br>
            <strong>Created At:</strong> ${new Date(details.created_at).toLocaleString()}<br>
            <strong>Name:</strong> ${details.name}<br>
            <strong>Notes:</strong> ${details.private_notes || 'N/A'}<br>
          </div>
          `;
        } else {
          html = 'Unknown payment type.';
        }

        Swal.fire({
          title: 'Transaction Details',
          html,
          icon: 'info',
          confirmButtonText: 'Close',
          cancelButtonText: 'Flag Transaction as Suspicious',
        });
      },
      error: (err) => {
        console.error('Error fetching payment details:', err);
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Failed to load payment details. Please try again.',
        });
      }
    });
  }


  exportPDF() {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });


    try {
      doc.addImage('./assets/icons/heroicons/outline/NearbTask.png', 'PNG', 140, 35, 28, 25);
    } catch (e) {
      console.error('Failed to load NearbyTasks.png:', e);
    }
    // Quanby Logo
    try {
      doc.addImage('./assets/icons/heroicons/outline/Quanby.png', 'PNG', 260, 35, 26, 25);
    } catch (e) {
      console.error('Failed to load Quanby.png:', e);
    }

  // Nearby Task Part
    const title = 'Nearby Task';
    doc.setFontSize(20);
    doc.setTextColor('#170A66');
    doc.text(title, 170, 52);

  // Line Part
    doc.setDrawColor(0, 0, 0);
    doc.setLineWidth(0.2);
    doc.line(30, 70, 415, 70);

  // Payment Review Part
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('Payment Reviews', 30, 90);

  // Date and Time Part
    const currentDate = new Date();
    const formattedDate = currentDate.toLocaleString('en-US', {
      month: '2-digit',
      day: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    }).replace(/,/, ', ');
    console.log('Formatted Date:', formattedDate);

  // Date and Time Position and Size
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    console.log('Rendering date at position x=400, y=90');
    doc.text(formattedDate, 310, 90);

    const columns = ['No', 'User Name', 'Amount', 'Payment Type', 'Created At', 'Transaction Date'];
    const rows = this.displayPaymentLogs.map((log, index) => [
      (this.currentPage - 1) * this.logsPerPage + index + 1,
      log.user_name || '',
      log.amount,
      log.payment_type || '',
      log.created_at || '',
      log.transaction_date || '' // Removed the erroneous ">"
    ]);
    autoTable(doc, {
      startY: 125,
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });

    doc.save('PaymentReviews.pdf');
  }
}
