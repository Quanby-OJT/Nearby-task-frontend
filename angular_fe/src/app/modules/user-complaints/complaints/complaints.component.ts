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
import { ReportCardComponent } from './report-card/report-card.component';
import { LoadingService } from 'src/app/services/loading.service';
import { firstValueFrom } from 'rxjs';
import { ComplaintsFilterService } from 'src/services/complaints-filter.service';

@Component({
  selector: 'app-complaints',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ClientComplaintComponent,
    TaskerComplaintComponent,
    ReportCardComponent,
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
    private authService: AuthService,
    private loadingService: LoadingService,
    public filterService: ComplaintsFilterService
  ) {}

  ngOnInit(): void {
    this.loadingService.show();
    this.isLoading = true;
    this.reportsSubscription = this.reportService.getReport().subscribe(
      (response: { success: boolean; reports: Report[] }) => {
        if (response.success) {
          this.reports = response.reports;
          this.filteredReports = [...this.reports];
          // Update the filter service with complaints data
          this.filterService.setComplaints(this.reports);
          this.updatePage();
          this.isLoading = false;
          this.loadingService.hide();
        }
      },
      (errors) => {
        console.error("Failed in getting reports: ", errors);
        this.isLoading = false;
        this.loadingService.hide();
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

    let handledBy = 'Empty'; // Default to Empty
    if (this.selectedReport.actionBy) {
      const firstName = this.selectedReport.actionBy.first_name || '';
      const middleName = this.selectedReport.actionBy.middle_name || '';
      const lastName = this.selectedReport.actionBy.last_name || '';

      // Check if all name parts are 'Unknown' or if the trimmed name is empty
      if (
        (firstName.toLowerCase() !== 'unknown' || middleName.toLowerCase() !== 'unknown' || lastName.toLowerCase() !== 'unknown') &&
        `${firstName} ${middleName} ${lastName}`.trim() !== ''
      ) {
        handledBy = `${firstName} ${middleName} ${lastName}`.trim();
      }
    }

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

  async banUser(reportId: number) {
    try {
      // Get the selected report
      const report = this.reports.find(r => r.report_id === reportId);
      if (!report) {
        Swal.fire({
          title: 'Error',
          text: 'Report not found',
          icon: 'error',
          confirmButtonText: 'OK',
          confirmButtonColor: '#3C28CC'
        });
        return;
      }

      // Check authorization based on roles and prior actions
      if (report.actionBy) {
        const priorActionRole = report.actionBy.user_role;
        
        // Case 1: Moderator trying to act on Admin's action
        if (this.userRole === 'Moderator' && priorActionRole === 'Admin') {
          Swal.fire({
            title: 'Access Denied',
            text: `You don't have authority to take action here since this action is made by an admin`,
            icon: 'error',
            confirmButtonText: 'OK',
            confirmButtonColor: '#3C28CC'
          });
          return;
        }
      }

      // If authorized, proceed with showing the ban reason modal
      const { value: reason } = await Swal.fire({
        title: 'Ban User',
        input: 'textarea',
        inputLabel: 'Reason for banning',
        inputPlaceholder: 'Enter your reason here...',
        showCancelButton: true,
        confirmButtonText: 'Ban',
        confirmButtonColor: '#3C28CC',
        cancelButtonText: 'Cancel',
        inputValidator: (value) => {
          if (!value) {
            return 'You need to write something!';
          }
          return null;
        }
      });

      if (reason) {
        this.loadingService.show();
        this.reportService.updateReportStatus(reportId, true, reason, 'ban').subscribe({
          next: () => {
            this.loadingService.hide();
            Swal.fire({
              title: 'Success!',
              text: 'User has been banned successfully',
              icon: 'success',
              confirmButtonText: 'OK',
              confirmButtonColor: '#3C28CC'
            });
            // Refresh reports and update filter service
            this.reportService.getReport().subscribe((response: { success: boolean; reports: Report[] }) => {
              if (response.success) {
                this.reports = response.reports;
                this.filteredReports = [...this.reports];
                this.filterService.setComplaints(this.reports);
                this.updatePage();
              }
            });
          },
          error: (error) => {
            this.loadingService.hide();
            Swal.fire({
              title: 'Error!',
              text: error.message || 'Failed to ban user',
              icon: 'error',
              confirmButtonText: 'OK',
              confirmButtonColor: '#3C28CC'
            });
          }
        });
      }
    } catch (error: any) {
      this.loadingService.hide();
      Swal.fire({
        title: 'Error!',
        text: error.message || 'Failed to process request',
        icon: 'error',
        confirmButtonText: 'OK',
        confirmButtonColor: '#3C28CC'
      });
    }
  }

  async unbanUser(reportId: number) {
    try {
      // Get the selected report
      const report = this.reports.find(r => r.report_id === reportId);
      if (!report) {
        Swal.fire({
          title: 'Error',
          text: 'Report not found',
          icon: 'error',
          confirmButtonText: 'OK',
          confirmButtonColor: '#3C28CC'
        });
        return;
      }

      // Check authorization based on roles and prior actions
      if (report.actionBy) {
        const priorActionRole = report.actionBy.user_role;
        
        // Case 1: Moderator trying to act on Admin's action
        if (this.userRole === 'Moderator' && priorActionRole === 'Admin') {
          Swal.fire({
            title: 'Access Denied',
            text: `You don't have authority to take action here since this action is made by an admin`,
            icon: 'error',
            confirmButtonText: 'OK',
            confirmButtonColor: '#3C28CC'
          });
          return;
        }
      }

      const { value: reason } = await Swal.fire({
        title: 'Unban User',
        html: `
          <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for unbanning</label>
          <input id="reason-input" class="swal2-input" placeholder="Enter reason" />
        `,
        showCancelButton: true,
        confirmButtonText: 'Confirm',
        cancelButtonText: 'Cancel',
        preConfirm: () => {
          const reasonInput = (document.getElementById('reason-input') as HTMLInputElement).value;
          if (!reasonInput) {
            Swal.showValidationMessage('Please provide a reason for this action');
          }
          return reasonInput;
        },
        willOpen: () => {
          const confirmButton = Swal.getConfirmButton();
          const reasonInput = document.getElementById('reason-input') as HTMLInputElement;
          if (confirmButton) {
            confirmButton.disabled = true;
          }
          reasonInput.addEventListener('input', () => {
            if (confirmButton) {
              confirmButton.disabled = !reasonInput.value.trim();
            }
          });
        }
      });

      if (reason) {
        this.loadingService.show();
        this.reportService.updateReportStatus(reportId, true, reason, 'unban').subscribe({
          next: (response) => {
            this.loadingService.hide();
            if (response.success) {
              Swal.fire('Unbanned!', 'User has been unbanned.', 'success').then(() => {
                this.reportService.getReport().subscribe((response: { success: boolean; reports: Report[] }) => {
                  if (response.success) {
                    this.reports = response.reports;
                    this.filteredReports = [...this.reports];
                    this.filterService.setComplaints(this.reports);
                    this.updatePage();
                  }
                });
              });
            } else {
              Swal.fire('Error!', 'Failed to unban the user.', 'error');
            }
          },
          error: (err) => {
            this.loadingService.hide();
            console.error('Unban User Error:', err);
            Swal.fire('Error!', err.message || 'Error unbanning user.', 'error');
          }
        });
      }
    } catch (error: any) {
      this.loadingService.hide();
      Swal.fire({
        title: 'Error!',
        text: error.message || 'Failed to process request',
        icon: 'error',
        confirmButtonText: 'OK',
        confirmButtonColor: '#3C28CC'
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