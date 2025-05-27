import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ClientComplaintComponent } from './client-complaint/client-complaint.component';
import { TaskerComplaintComponent } from './tasker-complaint/tasker-complaint.component';
import { ReportService } from 'src/app/services/report.service';
import { Subscription } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { AuthService } from 'src/app/services/auth.service';
import { Report } from 'src/model/complain';
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
    FormsModule,
    ClientComplaintComponent,
    TaskerComplaintComponent,
    AngularSvgIconModule
  ],
  templateUrl: './complaints.component.html',
  styleUrls: ['./complaints.component.css']
})
export class ComplaintsComponent implements OnInit, OnDestroy {
  reports: Report[] = [];
  filteredReports: Report[] = [];
  displayReports: Report[] = [];
  paginationButtons: (number | string)[] = [];
  reportsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  currentStatusFilter: string = '';
  selectedReport: Report | null = null;
  userRole: string | undefined;
  placeholderRows: any[] = []; 
  sortDirections: { [key: string]: 'asc' | 'desc' | 'default' } = {
    reporterName: 'default',
    createdAt: 'default'
  };
  sortColumn: 'reporterName' | 'createdAt' = 'createdAt';
  isLoading: boolean = true;

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
    this.isLoading = true;
    this.reportsSubscription = this.reportService.getReport().subscribe(
      (response: { success: boolean; reports: Report[] }) => {
        if (response.success) {
          this.reports = response.reports;
          this.filteredReports = [...this.reports];
          this.updatePage();
          this.isLoading = false;
        }
      },
      (errors) => {
        console.error("Failed in getting reports: ", errors);
        this.isLoading = false;
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

  public toggleSort(column: 'reporterName' | 'createdAt') {
    if (this.sortColumn !== column) {
      this.sortDirections[this.sortColumn] = 'default'; // Reset previous column
      this.sortColumn = column;
    }
    this.sortDirections[column] = this.sortDirections[column] === 'default' ? 'asc' : 
                                 this.sortDirections[column] === 'asc' ? 'desc' : 'default';
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

    // Apply sorting
    if (this.sortColumn === 'reporterName') {
      tempReports.sort((a, b) => {
        const nameA = [
          a.reporter.first_name || '',
          a.reporter.middle_name || '',
          a.reporter.last_name || ''
        ].filter(Boolean).join(' ').toLowerCase();
        const nameB = [
          b.reporter.first_name || '',
          b.reporter.middle_name || '',
          b.reporter.last_name || ''
        ].filter(Boolean).join(' ').toLowerCase();
        if (this.sortDirections['reporterName'] === 'asc' || this.sortDirections['reporterName'] === 'default') {
          return nameA.localeCompare(nameB); // A-Z
        } else {
          return nameB.localeCompare(nameA); // Z-A
        }
      });
    } else if (this.sortColumn === 'createdAt') {
      tempReports.sort((a, b) => {
        const dateA = new Date(a.created_at).getTime();
        const dateB = new Date(b.created_at).getTime();
        if (this.sortDirections['createdAt'] === 'asc') {
          return dateA - dateB; // Oldest to newest
        } else {
          return dateB - dateA; // Newest to oldest (default and desc)
        }
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

    for (let i = start; i <= end; i++) {
      this.paginationButtons.push(i);
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
    this.selectedReport = this.reports.find(report => report.report_id === reportId) || null;
    if (!this.selectedReport) {
      Swal.fire('Error', 'Report not found', 'error');
      return;
    }

    const handledBy = this.selectedReport.actionBy
      ? `${this.selectedReport.actionBy.first_name || ''} ${this.selectedReport.actionBy.middle_name || ''} ${this.selectedReport.actionBy.last_name || ''}`.trim()
      : 'Not Handled Yet';

    let imagesHtml = '';
    if (this.selectedReport.images) {
      try {
        let imageUrls: string[] = [];

        if (this.selectedReport.images.startsWith('[')) {
          imageUrls = JSON.parse(this.selectedReport.images);
        } else {
          imageUrls = [this.selectedReport.images]; 
        }
        if (imageUrls.length > 0) {
          imagesHtml = imageUrls.map(url => `<img src="${url}" alt="Report Image" style="width: 100px; height: 100px; object-fit: cover; margin-right: 10px; margin-bottom: 10px;" onclick="window.open('${url}', '_blank');" />`).join('');
        } else {
          imagesHtml = '<div>No images available</div>';
        }
      } catch (e) {
        console.error('Error parsing images:', e);
        imagesHtml = `<img src="${this.selectedReport.images}" alt="Report Image" style="width: 100px; height: 100px; object-fit: cover; margin-right: 10px; margin-bottom: 10px;" onclick="window.open('${this.selectedReport.images}', '_blank');" />`;
      }
    } else {
      imagesHtml = '<div>No images available</div>';
    }

    // Conditionally include the Moderator section based on userRole
    const moderatorHtml = this.userRole === 'Admin'
      ? `
        <div class="flex mb-4">
          <div class="font-bold w-32">Moderator:</div>
          <div>${handledBy}</div>
        </div>`
      : '';

    const htmlContent = `
      <div style="max-height: 400px; overflow-y: auto; padding-right: 10px;">
        <div class="flex mb-4">
          <div class="font-bold w-32">Reporter:</div>
          <div>${this.selectedReport.reporter.first_name} ${this.selectedReport.reporter.middle_name || ''} ${this.selectedReport.reporter.last_name}</div>
        </div>
        <div class="flex mb-4">
          <div class="font-bold w-32">Violator:</div>
          <div>${this.selectedReport.violator.first_name} ${this.selectedReport.violator.middle_name || ''} ${this.selectedReport.violator.last_name}</div>
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
        ${moderatorHtml}
        <div class="mb-4">
          <div class="font-bold w-32">Evidence:</div>
          <div class="flex flex-wrap">${imagesHtml}</div>
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
        this.banUser(this.selectedReport!.report_id);
      } else if (result.isDismissed && result.dismiss === Swal.DismissReason.cancel) {
        this.unbanUser(this.selectedReport!.report_id);
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
              this.reportService.getReport().subscribe((response: { success: boolean; reports: Report[] }) => {
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
      this.reportService.updateReportStatus(reportId, true).subscribe({
        next: (response) => {
          if (response.success) {
            Swal.fire('Unbanned!', 'User has been unbanned.', 'success').then(() => {
              // Refresh the report list after unbanning
              this.reportService.getReport().subscribe((response: { success: boolean; reports: Report[] }) => {
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
      ? ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status', 'Moderator']
      : ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status'];
    const rows = this.displayReports.map((report, index) => {
      const reporterName = report.reporter
        ? `${report.reporter.first_name || ''} ${report.reporter.middle_name || ''} ${report.reporter.last_name || ''}`.trim()
        : 'Unknown';
      const violatorName = report.violator
        ? `${report.violator.first_name || ''} ${report.violator.middle_name || ''} ${report.violator.last_name || ''}`.trim()
        : 'Unknown';
      const handledBy = report.actionBy
        ? `${report.actionBy.first_name || ''} ${report.actionBy.middle_name || ''} ${report.actionBy.last_name || ''}`.trim()
        : 'Empty';
      const baseRow = [
        index + 1,
        `"${reporterName}"`,
        `"${violatorName}"`,
        `"${report.reporter?.user_role || 'Unknown'}"`,
        `"${report.violator?.user_role || 'Unknown'}"`,
        `"${report.created_at || 'N/A'}"`,
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

    try {
      doc.addImage('./assets/icons/heroicons/outline/NearbTask.png', 'PNG', 140, 35, 28, 25); 
    } catch (e) {
      console.error('Failed to load NearbyTasks.png:', e);
    }

    try {
      doc.addImage('./assets/icons/heroicons/outline/Quanby.png', 'PNG', 260, 35, 26, 25);
    } catch (e) {
      console.error('Failed to load Quanby.png:', e);
    }

    const title = 'Nearby Task';
    doc.setFontSize(20);
    doc.setTextColor('#170A66');
    doc.text(title, 170, 52);

   // Line Part
   doc.setDrawColor(0, 0, 0);
   doc.setLineWidth(0.2);
   doc.line(30, 70, 415, 70);

   doc.setFontSize(12);
   doc.setTextColor('#000000');
   doc.text('Complain Management', 30, 90);

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

    const headers = isAdmin
      ? ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status', 'Moderator']
      : ['No', 'Reporter Name', 'Violator Name', 'Reporter Role', 'Violator Role', 'Date', 'Status'];
    const rows = this.displayReports.map((report, index) => {
      const reporterName = report.reporter
        ? `${report.reporter.first_name || ''} ${report.reporter.middle_name || ''} ${report.reporter.last_name || ''}`.trim()
        : 'Unknown';
      const violatorName = report.violator
        ? `${report.violator.first_name || ''} ${report.violator.middle_name || ''} ${report.violator.last_name || ''}`.trim()
        : 'Unknown';
      const handledBy = report.actionBy
        ? `${report.actionBy.first_name || ''} ${report.actionBy.middle_name || ''} ${report.actionBy.last_name || ''}`.trim()
        : 'Empty';
      const baseRow = [
        index + 1,
        reporterName,
        violatorName,
        report.reporter?.user_role || 'Unknown',
        report.violator?.user_role || 'Unknown',
        report.created_at || 'N/A',
        report.status ? 'Processed' : 'Pending',
      ];
      if (isAdmin) {
        baseRow.push(handledBy);
      }
      return baseRow;
    });
    autoTable(doc, {
      startY: 125,
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