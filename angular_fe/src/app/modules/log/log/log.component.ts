import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { UserLogService } from 'src/app/services/log.service';
import { LoadingService } from 'src/app/services/loading.service';
import { Log } from 'src/model/log'; 
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: 'app-log',
  standalone: true,
  imports: [CommonModule, AngularSvgIconModule],
  templateUrl: './log.component.html',
  styleUrl: './log.component.css',
})
export class LogComponent implements OnInit, OnDestroy {
  logs: Log[] = [];
  filteredLogs: Log[] = [];
  displayLogs: Log[] = [];
  paginationButtons: (number | string)[] = [];
  logsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  currentRoleFilter: string = ''; 
  currentStatusFilter: string = ''; 
  placeholderRows: any[] = [];
  sortDirection: 'asc' | 'desc' | 'default' = 'default'; 
  isLoading: boolean = false;
  private logsSubscription!: Subscription;

  constructor(
    private userlogService: UserLogService,
    private loadingService: LoadingService
  ) {}

  ngOnInit(): void {
    this.loadingService.show();
    this.logsSubscription = this.userlogService.getUserLogs().subscribe({
      next: (logs: Log[]) => {
        this.logs = logs;
        this.filteredLogs = [...logs];
        this.updatePage();
        this.isLoading = true;
        this.loadingService.hide();
      },
      error: (error) => {
        console.error("Error getting logs:", error);
        this.isLoading = true;
        this.loadingService.hide();
      }
    });
  }

  ngOnDestroy(): void {
    if (this.logsSubscription) {
      this.logsSubscription.unsubscribe();
    }
  }

  searchLogs(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  filterLogs(event: Event) {
    const target = event.target as HTMLSelectElement;
    if (target.name === 'role') {
      this.currentRoleFilter = target.value;
    } else if (target.name === 'status') {
      this.currentStatusFilter = target.value;
    }
    this.applyFilters();
  }

  applyFilters() {
    let tempLogs = [...this.logs];

    // Apply search filter if there's a search term
    if (this.currentSearchText) {
      tempLogs = tempLogs.filter(log => {
        // Ensure all name parts are strings and handle null/undefined
        const firstName = (log.user.first_name || '').toLowerCase();
        const middleName = (log.user.middle_name || '').toLowerCase();
        const lastName = (log.user.last_name || '').toLowerCase();

        // Create full name with proper spacing
        const fullName = [firstName, middleName, lastName]
          .filter(name => name) // Remove empty strings
          .join(' ');

        // Split search terms to allow matching individual words
        const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);

        // Check if all search terms are present in the full name
        return searchTerms.every(term => fullName.includes(term));
      });
    }

    // Apply role filter if a role is selected
    if (this.currentRoleFilter) {
      tempLogs = tempLogs.filter(log => {
        const userRole = log.user.user_role || '';
        return userRole.toLowerCase() === this.currentRoleFilter.toLowerCase();
      });
    }

    // Apply status filter if a status is selected
    if (this.currentStatusFilter) {
      tempLogs = tempLogs.filter(log => {
        const logStatus = log.user.status ? 'active' : 'disabled';
        return logStatus === this.currentStatusFilter;
      });
    }

    // Apply sorting
    tempLogs.sort((a, b) => {
      if (this.sortDirection === 'default') {
        // Sort by created_at (newest first)
        const dateA = new Date(a.created_at).getTime();
        const dateB = new Date(b.created_at).getTime();
        return dateB - dateA;
      } else {
        // Sort by user name
        const nameA = `${a.user.first_name || ''} ${a.user.middle_name || ''} ${a.user.last_name || ''}`.trim().toLowerCase();
        const nameB = `${b.user.first_name || ''} ${b.user.middle_name || ''} ${b.user.last_name || ''}`.trim().toLowerCase();
        if (this.sortDirection === 'asc') {
          return nameA.localeCompare(nameB);
        } else {
          return nameB.localeCompare(nameA);
        }
      }
    });

    this.filteredLogs = tempLogs;
    this.currentPage = 1;
    this.updatePage();
  }

  toggleSort() {
    // Cycle through: default -> asc -> desc -> default
    this.sortDirection = this.sortDirection === 'default' ? 'asc' : 
                        this.sortDirection === 'asc' ? 'desc' : 'default';
    this.applyFilters();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredLogs.length / this.logsPerPage);
    this.displayLogs = this.filteredLogs.slice(
      (this.currentPage - 1) * this.logsPerPage,
      this.currentPage * this.logsPerPage
    );
    this.startIndex = (this.currentPage - 1) * this.logsPerPage + 1;
    this.endIndex = Math.min(this.currentPage * this.logsPerPage, this.filteredLogs.length);
    
    // Calculate the number of empty rows based on logsPerPage
    const placeholderCount = this.logsPerPage - this.displayLogs.length;
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

  goToPage(page: number | string) {
    const pageNum = typeof page === 'string' ? parseInt(page, 10) : page;
    if (pageNum >= 1 && pageNum <= this.totalPages) {
      this.currentPage = pageNum;
      this.updatePage();
    }
  }

  exportCSV() {
    const headers = ['No', 'User Name', 'User Role', 'Time Start', 'Time End', 'Status'];
    const rows = this.displayLogs.map((log, index) => {
      const userName = log.user
        ? `${log.user.first_name || ''} ${log.user.middle_name || ''} ${log.user.last_name || ''}`.trim()
        : '';
      const userRole = log.user.user_role ? log.user.user_role : 'Null';
      const timeEnd = log.logged_out ? log.logged_out : 'Empty';
      const status = log.user.status ? 'Online' : 'Offline';
      return [
        index + 1,
        `"${userName}"`,
        `"${userRole}"`,
        `"${log.logged_in || ''}"`,
        `"${timeEnd}"`,
        `"${status}"`
      ];
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'UserLogs.csv');
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

    // Logs Part
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('User Logs', 30, 90);

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

    const headers = ['No', 'User Name', 'User Role', 'Time Start', 'Time End', 'Status'];
    const rows = this.displayLogs.map((log, index) => {
      const userName = log.user
        ? `${log.user.first_name || ''} ${log.user.middle_name || ''} ${log.user.last_name || ''}`.trim()
        : '';
      const userRole = log.user.user_role ? log.user.user_role : 'Null';
      const timeEnd = log.logged_out ? log.logged_out : 'Empty';
      const status = log.user.status ? 'Online' : 'Offline';
      return [
        index + 1,
        userName,
        userRole,
        log.logged_in || '',
        timeEnd,
        status
      ];
    });
    autoTable(doc, {
      startY: 125,
      head: [headers],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('UserLogs.pdf');
  }
}