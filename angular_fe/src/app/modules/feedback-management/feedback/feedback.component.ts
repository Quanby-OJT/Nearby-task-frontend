import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { FeedbackService } from 'src/app/services/feedback.service';
import { Feedback } from 'src/model/feedback'; 
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { LoadingService } from 'src/app/services/loading.service';

@Component({
  selector: 'app-feedback',
  imports: [CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './feedback.component.html',
  styleUrl: './feedback.component.css'
})
export class FeedbackComponent implements OnInit {
  feedbacks: Feedback[] = [];
  filteredFeedbacks: Feedback[] = [];
  displayFeedbacks: Feedback[] = [];
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
  sortDirections: { [key: string]: 'asc' | 'desc' | 'default' } = {
    taskerName: 'default',
    createdAt: 'default',
    rating: 'default'
  };
  sortColumn: 'taskerName' | 'createdAt' | 'rating' = 'createdAt';

  constructor(
    private feedbackService: FeedbackService,
    private loadingService: LoadingService
  ) {}

  ngOnInit(): void {
    this.isLoading = true;
    this.loadingService.show();
    this.feedbackService.getFeedback().subscribe(
      (response: { feedbacks: Feedback[] }) => {
        console.log('Received feedback data:', response);
        this.feedbacks = response.feedbacks || [];
        this.filteredFeedbacks = [...this.feedbacks];
        this.applyFilters(); // Apply default sorting on load
        this.updatePage();
        this.isLoading = false;
        this.loadingService.hide();
      },
      (error) => {
        console.error('Error fetching feedbacks', error);
        this.feedbacks = [];
        this.filteredFeedbacks = [];
        this.displayFeedbacks = [];
        this.updatePage();
        this.isLoading = false;
        this.loadingService.hide();
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

    // Apply sorting based on the selected column
    if (this.sortColumn === 'taskerName') {
      tempFeedbacks.sort((a, b) => {
        const nameA = `${a.tasker?.user?.first_name || ''} ${a.tasker?.user?.middle_name || ''} ${a.tasker?.user?.last_name || ''}`.trim().toLowerCase();
        const nameB = `${b.tasker?.user?.first_name || ''} ${b.tasker?.user?.middle_name || ''} ${b.tasker?.user?.last_name || ''}`.trim().toLowerCase();
        if (this.sortDirections['taskerName'] === 'asc' || this.sortDirections['taskerName'] === 'default') {
          return nameA.localeCompare(nameB); // A-Z
        } else {
          return nameB.localeCompare(nameA); // Z-A
        }
      });
    } else if (this.sortColumn === 'createdAt') {
      tempFeedbacks.sort((a, b) => {
        const dateA = new Date(a.created_at).getTime();
        const dateB = new Date(b.created_at).getTime();
        if (this.sortDirections['createdAt'] === 'asc') {
          return dateA - dateB; // Oldest to newest
        } else {
          return dateB - dateA; // Newest to oldest (default and desc)
        }
      });
    } else if (this.sortColumn === 'rating') {
      tempFeedbacks.sort((a, b) => {
        const ratingA = parseFloat(a.rating) || 0;
        const ratingB = parseFloat(b.rating) || 0;
        if (this.sortDirections['rating'] === 'asc') {
          return ratingA - ratingB; 
        } else {
          return ratingB - ratingA; 
        }
      });
    }

    this.filteredFeedbacks = tempFeedbacks;
    this.currentPage = 1;
    this.updatePage();
  }

  public toggleSort(column: 'taskerName' | 'createdAt' | 'rating') {
    if (this.sortColumn !== column) {
      this.sortDirections[this.sortColumn] = 'default'; // Reset previous column
      this.sortColumn = column;
    }
    this.sortDirections[column] = this.sortDirections[column] === 'default' ? 'asc' : 
                                 this.sortDirections[column] === 'asc' ? 'desc' : 'default';
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

    // Feedback Part
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('Feedback Management', 30, 90);

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
      startY: 125,
      head: [headers],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('Feedbacks.pdf');
  }
}