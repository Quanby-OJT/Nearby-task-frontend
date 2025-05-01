import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { FeedbackService } from 'src/app/services/feedback.service';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: 'app-feedback',
  imports: [CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './feedback.component.html',
  styleUrl: './feedback.component.css'
})
export class FeedbackComponent implements OnInit {
  feedbacks: any[] = [];
  filteredFeedbacks: any[] = [];
  displayFeedbacks: any[] = [];
  currentSearchText: string = '';
  currentFilterType: string = '';
  logsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  paginationButtons: (number | string)[] = [];
  placeholderRows: any[] = [];
  sortDirection: 'asc' | 'desc' = 'desc';

  constructor(private feedbackService: FeedbackService) {}

  ngOnInit(): void {
    this.feedbackService.getFeedback().subscribe(
      (response: any) => {
        console.log('Received feedback data:', response);
        this.feedbacks = response.feedbacks || [];
        this.filteredFeedbacks = [...this.feedbacks];
        this.updatePage();
      },
      (error) => {
        console.error('Error fetching feedbacks', error);
        this.feedbacks = [];
        this.filteredFeedbacks = [];
        this.displayFeedbacks = [];
        this.updatePage();
      }
    );
  }

  searchFeedback(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  applyFilters() {
    let tempFeedbacks = [...this.feedbacks];

    if (this.currentSearchText) {
      const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);
      tempFeedbacks = tempFeedbacks.filter(feedback => {
        const firstName = feedback.tasker?.user?.first_name?.toLowerCase() || '';
        const middleName = feedback.tasker?.user?.middle_name?.toLowerCase() || '';
        const lastName = feedback.tasker?.user?.last_name?.toLowerCase() || '';
        
        const fullName = [firstName, middleName, lastName].filter(name => name).join(' ');

        return searchTerms.every(term => fullName.includes(term));
      });
    }

    if (this.currentFilterType) {
      tempFeedbacks = tempFeedbacks.filter(feedback => feedback.reported === this.currentFilterType);
    }

    // Apply simple reverse sort
    if (this.sortDirection === 'desc') {
      tempFeedbacks = tempFeedbacks.reverse();
    }

    // Log sorted feedbacks for debugging
    console.log(`Sorted feedbacks (${this.sortDirection}):`, tempFeedbacks.map(feedback => ({
      feedback_id: feedback.feedback_id || 'N/A',
      tasker: `${feedback.tasker?.user?.first_name || ''} ${feedback.tasker?.user?.last_name || ''}`,
      rating: feedback.rating || 'N/A',
      created_at: feedback.created_at || 'N/A'
    })));

    this.filteredFeedbacks = tempFeedbacks;
    this.currentPage = 1;
    this.updatePage();
  }

  public toggleSort() {
    this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    this.applyFilters();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredFeedbacks.length / this.logsPerPage);
    if (this.totalPages === 0) {
        this.totalPages = 1;
    }
    this.currentPage = Math.max(1, Math.min(this.currentPage, this.totalPages));

    const start = (this.currentPage - 1) * this.logsPerPage;
    const end = start + this.logsPerPage;
    this.displayFeedbacks = this.filteredFeedbacks.slice(start, end);
    this.startIndex = this.filteredFeedbacks.length === 0 ? 0 : start + 1;
    this.endIndex = Math.min(end, this.filteredFeedbacks.length);
    
    // Calculate the number of empty rows based on logsPerPage
    const placeholderCount = this.logsPerPage - this.displayFeedbacks.length;
    this.placeholderRows = Array(placeholderCount).fill({});
    
    this.makePaginationButtons();
  }

  makePaginationButtons() {
    const maxButtons = 3;
    this.paginationButtons = [];

    if (this.totalPages <= 1) return;

    let startPage = Math.max(1, this.currentPage - 1);
    let endPage = Math.min(this.totalPages, startPage + maxButtons - 1);

    if (endPage === this.totalPages) {
        startPage = Math.max(1, this.totalPages - maxButtons + 1);
    }
    
    if (startPage === 1) {
       endPage = Math.min(this.totalPages, maxButtons);
    }

    for (let i = startPage; i <= endPage; i++) {
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
    if (typeof page === 'number' && page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
      this.updatePage();
    }
  }

  exportCSV() {
    const headers = ['No', 'Tasker Name', 'Feedback', 'Rating', 'Client', 'Reported', 'Created At'];
    const rows = this.displayFeedbacks.map((feedback, index) => {
      const taskerName = feedback.tasker?.user
        ? `${feedback.tasker.user.first_name || ''} ${feedback.tasker.user.middle_name || ''} ${feedback.tasker.user.last_name || ''}`.trim()
        : '';
      const clientName = feedback.task_taken?.client?.user
        ? `${feedback.task_taken.client.user.first_name || ''} ${feedback.task_taken.client.user.middle_name || ''} ${feedback.task_taken.client.user.last_name || ''}`.trim()
        : '';
      const reported = feedback.reported ? feedback.reported : 'Empty';
      return [
        (this.currentPage - 1) * this.logsPerPage + index + 1,
        `"${taskerName}"`,
        `"${feedback.feedback || ''}"`,
        feedback.rating || '',
        `"${clientName}"`,
        `"${reported}"`,
        `"${feedback.created_at || ''}"`
      ];
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'Feedbacks.csv');
  }

  exportPDF() {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });
    const title = 'Feedback Management';
    doc.setFontSize(20);
    doc.text(title, 170, 45);
    const headers = ['No', 'Tasker Name', 'Feedback', 'Rating', 'Client', 'Reported', 'Created At'];
    const rows = this.displayFeedbacks.map((feedback, index) => {
      const taskerName = feedback.tasker?.user
        ? `${feedback.tasker.user.first_name || ''} ${feedback.tasker.user.middle_name || ''} ${feedback.tasker.user.last_name || ''}`.trim()
        : '';
      const clientName = feedback.task_taken?.client?.user
        ? `${feedback.task_taken.client.user.first_name || ''} ${feedback.task_taken.client.user.middle_name || ''} ${feedback.task_taken.client.user.last_name || ''}`.trim()
        : '';
      const reported = feedback.reported ? feedback.reported : 'Empty';
      return [
        (this.currentPage - 1) * this.logsPerPage + index + 1,
        taskerName,
        feedback.feedback || '',
        feedback.rating || '',
        clientName,
        reported,
        feedback.created_at || ''
      ];
    });
    autoTable(doc, {
      startY: 100,
      head: [headers],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('Feedbacks.pdf');
  }
}