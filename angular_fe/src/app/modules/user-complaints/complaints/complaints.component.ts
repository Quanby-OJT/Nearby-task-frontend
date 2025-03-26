import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ClientComplaintComponent } from './client-complaint/client-complaint.component';
import { TaskerComplaintComponent } from './tasker-complaint/tasker-complaint.component';
import { ReportService } from 'src/app/services/report.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-complaints',
  standalone: true,
  imports: [
    CommonModule,
    ClientComplaintComponent,
    TaskerComplaintComponent
  ],
  templateUrl: './complaints.component.html',
  styleUrls: ['./complaints.component.css']
})
export class ComplaintsComponent implements OnInit, OnDestroy {
  reports: any[] = [];
  filteredReports: any[] = [];
  displayReports: any[] = [];
  paginationButtons: (number | string)[] = [];
  reportsPerPage: number = 10;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  // Store the current search term and filter value to combine both filters
  currentSearchText: string = '';
  currentStatusFilter: string = '';

  private reportsSubscription!: Subscription;

  constructor(
    private reportService: ReportService
  ){}

  ngOnInit(): void {
    this.reportsSubscription = this.reportService.getReport().subscribe(
      (response) => {
        if (response.success){
          this.reports = response.reports;
          this.filteredReports = [...this.reports];
          this.updatePage();
        }
      },
      (errors) => {
        console.error("Failed in getting reports: ", errors);
      }
    );
  }

  ngOnDestroy(): void{
    if(this.reportsSubscription){
      this.reportsSubscription.unsubscribe();
    }
  }

  searchReports(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.toLowerCase();
    this.applyFilters();
  }

  // Handle the status filter when the user selects an option from the dropdown
  filterReports(event: Event) {
    this.currentStatusFilter = (event.target as HTMLSelectElement).value;
    this.applyFilters();
  }

  // Combine search and filter logic to update filteredReports
  applyFilters() {
    let tempReports = [...this.reports];

    // Apply search filter if there's a search term
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

    // Apply status filter if a status is selected
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
}