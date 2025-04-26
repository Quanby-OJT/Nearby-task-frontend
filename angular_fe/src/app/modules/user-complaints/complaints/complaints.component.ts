import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ClientComplaintComponent } from './client-complaint/client-complaint.component';
import { TaskerComplaintComponent } from './tasker-complaint/tasker-complaint.component';
import { ReportService } from 'src/app/services/report.service';
import { Subscription } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { AuthService } from 'src/app/services/auth.service';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import Swal from 'sweetalert2';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: 'app-complaints',
  standalone: true,
  imports: [
    CommonModule,
    ClientComplaintComponent,
    TaskerComplaintComponent,
    AngularSvgIconModule
  ],
  templateUrl: './complaints.component.html',
  styleUrls: ['./complaints.component.css']
})
export class ComplaintsComponent implements OnInit, OnDestroy {
  reports: any[] = [];
  filteredReports: any[] = [];
  displayReports: any[] = [];
  paginationButtons: (number | string)[] = [];
  reportsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  currentStatusFilter: string = '';
  selectedReport: any = null;
  userRole: string | undefined;
  placeholderRows: any[] = []; // Added for placeholder rows

  private reportsSubscription!: Subscription;

  // References to child components
  @ViewChild(ClientComplaintComponent) clientComplaintComponent!: ClientComplaintComponent;
  @ViewChild(TaskerComplaintComponent) taskerComplaintComponent!: TaskerComplaintComponent;

  constructor(
    private reportService: ReportService,
    private sessionStorage: SessionLocalStorage,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.reportsSubscription = this.reportService.getReport().subscribe(
      (response) => {
        if (response.success) {
          this.reports = response.reports;
          this.filteredReports = [...this.reports];
          this.updatePage();
        }
      },
      (errors) => {
        console.error("Failed in getting reports: ", errors);
      }
    );

    this.authService.userInformation().subscribe(
      (response: any) => {
        this.userRole = response.user.user_role;
      },
      (error: any) => {
        console.error('Error fetching user info:', error);
      }
    );
  }

  ngOnDestroy(): void {
    if (this.reportsSubscription) {
      this.reportsSubscription.unsubscribe();
    }
    this.stopAutoSwipe();
  }

  searchReports(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.toLowerCase();
    this.applyFilters();
  }

  filterReports(event: Event) {
    this.currentStatusFilter = (event.target as HTMLSelectElement).value;
    this.applyFilters();
  }

  applyFilters() {
    let tempReports = [...this.reports];

    if (this.currentSearchText) {
      tempReports = tempReports.filter(report => {
        const reporterFullName = [
          report.reporter.first_name || '',
          report.reporter.middle_name || '',
          report.reporter.last_name || ''
        ].filter(Boolean).join(' ').toLowerCase();

        const violatorFullName = [
          report.violator.first_name || '',
          report.violator.middle_name || '',
          report.violator.last_name || ''
        ].filter(Boolean).join(' ').toLowerCase();

        return reporterFullName.includes(this.currentSearchText) || violatorFullName.includes(this.currentSearchText);
      });
    }

    if (this.currentStatusFilter) {
      tempReports = tempReports.filter(report => {
        const reportStatus = report.status ? 'processed' : 'pending';
        return reportStatus === this.currentStatusFilter;
      });
    }

    this.filteredReports = tempReports;
    this.currentPage = 1;
    this.updatePage();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredReports.length / this.reportsPerPage);
    this.displayReports = this.filteredReports.slice(
      (this.currentPage - 1) * this.reportsPerPage,
      this.currentPage * this.reportsPerPage
    );
    this.startIndex = (this.currentPage - 1) * this.reportsPerPage + 1;
    this.endIndex = Math.min(this.currentPage * this.reportsPerPage, this.filteredReports.length);
    
    // Calculate the number of empty rows based on reportsPerPage
    const placeholderCount = this.reportsPerPage - this.displayReports.length;
    this.placeholderRows = Array(placeholderCount).fill({});
    
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

  changeReportsPerPage(event: Event) {
    this.reportsPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
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

  openModal(reportId: number) {
    this.selectedReport = this.reports.find(report => report.report_id === reportId);
    if (!this.selectedReport) {
      Swal.fire('Error', 'Report not found', 'error');
      return;
    }

    const handledBy = this.selectedReport.action_by
      ? `${this.selectedReport.actionBy.first_name || ''} ${this.selectedReport.actionBy.middle_name || ''} ${this.selectedReport.actionBy.last_name || ''}`.trim()
      : 'Not Handled Yet';

    const htmlContent = `
      <div style="max-height: 400px; overflow-y: auto; padding-right: 10px;">
        <div class="flex mb-4">
          <div class="font-bold w-32">Report ID:</div>
          <div>${this.selectedReport.report_id}</div>
        </div>
        <div class="flex mb-4">
          <div class="font-bold w-32">Reporter:</div>
          <div>${this.selectedReport.reporter.first_name} ${this.selectedReport.reporter.middle_name} ${this.selectedReport.reporter.last_name}</div>
        </div>
        <div class="flex mb-4">
          <div class="font-bold w-32">Violator:</div>
          <div>${this.selectedReport.violator.first_name} ${this.selectedReport.violator.middle_name} ${this.selectedReport.violator.last_name}</div>
        </div>
        <div class="flex mb-4">
          <div class="font-bold w-32">Reason:</div>
          <div>${this.selectedReport.reason}</div>
        </div>
        <div class="flex mb-4">
          <div class="font-bold w-32">Status:</div>
          <div>${this.selectedReport.status ? 'Processed' : 'Pending'}</div>
        </div>
        <div class="flex mb-4">
          <div class="font-bold w-32">Created At:</div>
          <div>${this.selectedReport.created_at}</div>
        </div>
        <div class="flex mb-4">
          <div class="font-bold w-32">Handled By:</div>
          <div>${handledBy}</div>
        </div>
      </div>
    `;

    Swal.fire({
      title: 'Report Details',
      html: htmlContent,
      width: '800px',
      showCancelButton: true,
      confirmButtonText: 'Ban',
      confirmButtonColor: '#d33',
      cancelButtonText: 'Unban',
      cancelButtonColor: '#28a745',
      showCloseButton: true,
      showDenyButton: true,
      denyButtonText: 'Close',
      denyButtonColor: '#3085d6',
      customClass: {
        htmlContainer: 'text-left'
      },
      didOpen: () => {
        const container = document.querySelector('.swal2-html-container > div');
        if (container) {
          container.scrollTop = container.scrollHeight;
        }
      }
    }).then((result) => {
      if (result.isConfirmed) {
        this.banUser(this.selectedReport.report_id);
      } else if (result.isDismissed && result.dismiss === Swal.DismissReason.cancel) {
        this.unbanUser(this.selectedReport.report_id);
      }
    });
  }

  banUser(reportId: number) {
    if (reportId) {
      this.reportService.updateReportStatus(reportId, true).subscribe({
        next: (response) => {
          if (response.success) {
            Swal.fire('Banned!', 'User has been banned.', 'success').then(() => {
              // Refresh the report list after banning
              this.reportService.getReport().subscribe((response) => {
                if (response.success) {
                  this.reports = response.reports;
                  this.filteredReports = [...this.reports];
                  this.updatePage();
                }
              });
            });
          } else {
            Swal.fire('Error!', 'Failed to ban the user.', 'error');
          }
        },
        error: (err) => {
          Swal.fire('Error!', 'Error banning user.', 'error');
        }
      });
    }
  }

  unbanUser(reportId: number) {
    if (reportId) {
      this.reportService.updateReportStatus(reportId, false).subscribe({
        next: (response) => {
          if (response.success) {
            Swal.fire('Unbanned!', 'User has been unbanned.', 'success').then(() => {
              // Refresh the report list after unbanning
              this.reportService.getReport().subscribe((response) => {
                if (response.success) {
                  this.reports = response.reports;
                  this.filteredReports = [...this.reports];
                  this.updatePage();
                }
              });
            });
          } else {
            Swal.fire('Error!', 'Failed to unban the user.', 'error');
          }
        },
        error: (err) => {
          Swal.fire('Error!', 'Error unbanning user.', 'error');
        }
      });
    }
  }

  exportCSV() {
    const isAdmin = this.userRole === 'Admin';
    const headers = isAdmin
      ? ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status', 'Handled By']
      : ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status'];
    const rows = this.displayReports.map((report, index) => {
      const reporterName = report.reporter
        ? `${report.reporter.first_name || ''} ${report.reporter.middle_name || ''} ${report.reporter.last_name || ''}`.trim()
        : '';
      const violatorName = report.violator
        ? `${report.violator.first_name || ''} ${report.violator.middle_name || ''} ${report.violator.last_name || ''}`.trim()
        : '';
      const handledBy = report.action_by
        ? `${report.actionBy.first_name || ''} ${report.actionBy.middle_name || ''} ${report.actionBy.last_name || ''}`.trim()
        : 'null';
      const baseRow = [
        index + 1,
        `"${reporterName}"`,
        `"${violatorName}"`,
        `"${report.reporter?.user_role || ''}"`,
        `"${report.violator?.user_role || ''}"`,
        `"${report.created_at || ''}"`,
        report.status ? 'Processed' : 'Pending',
      ];
      if (isAdmin) {
        baseRow.push(`"${handledBy}"`);
      }
      console.log('CSV Row:', baseRow);
      return baseRow;
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'UserComplaints.csv');
  }

  exportPDF() {
    const isAdmin = this.userRole === 'Admin';
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });
    const title = 'User Complaints';
    doc.setFontSize(20);
    doc.text(title, 170, 45);
    const headers = isAdmin
      ? ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status', 'Handled By']
      : ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status'];
    const rows = this.displayReports.map((report, index) => {
      const reporterName = report.reporter
        ? `${report.reporter.first_name || ''} ${report.reporter.middle_name || ''} ${report.reporter.last_name || ''}`.trim()
        : '';
      const violatorName = report.violator
        ? `${report.violator.first_name || ''} ${report.violator.middle_name || ''} ${report.violator.last_name || ''}`.trim()
        : '';
      const handledBy = report.action_by
        ? `${report.actionBy.first_name || ''} ${report.actionBy.middle_name || ''} ${report.actionBy.last_name || ''}`.trim()
        : 'null';
      const baseRow = [
        index + 1,
        reporterName,
        violatorName,
        report.reporter?.user_role || '',
        report.violator?.user_role || '',
        report.created_at || '',
        report.status ? 'Processed' : 'Pending',
      ];
      if (isAdmin) {
        baseRow.push(handledBy);
      }
      return baseRow;
    });
    autoTable(doc, {
      startY: 100,
      head: [headers],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('UserComplaints.pdf');
  }

  // Auto-swipe control forwarded to child components
  startAutoSwipe() {
    if (this.clientComplaintComponent) {
      this.clientComplaintComponent.startAutoSwipe();
    }
    if (this.taskerComplaintComponent) {
      this.taskerComplaintComponent.startAutoSwipe();
    }
  }

  stopAutoSwipe() {
    if (this.clientComplaintComponent) {
      this.clientComplaintComponent.stopAutoSwipe();
    }
    if (this.taskerComplaintComponent) {
      this.taskerComplaintComponent.stopAutoSwipe();
    }
  }
}