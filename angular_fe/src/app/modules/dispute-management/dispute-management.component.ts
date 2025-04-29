import { Component } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DisputeManagementService } from 'src/app/services/dispute-management.service';


import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';


@Component({
  selector: 'app-dispute-management',
  standalone: true,
  imports: [FormsModule, AngularSvgIconModule, CommonModule],
  templateUrl: './dispute-management.component.html',
  styleUrl: './dispute-management.component.css'
})

export class DisputeManagementComponent {
  disputes: any[] = [];
  filteredDisputes: any[] = [];
  displayDisputes: any[] = [];
  currentSearchText: string = '';
  currentFilterType: string = '';
  logsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  isLoading: boolean = false;
  paginationButtons: (number | string)[] = [];
  placeholderRows: any[] = []; // Added for placeholder rows

  constructor(private disputeService: DisputeManagementService) {}

  ngOnInit(): void {
    this.isLoading = true
    this.disputeService.getAllDisputes().subscribe(
      (response: any) => {
        console.log('Received dispute data:', response);
        this.disputes = response.data || [];
        this.isLoading = false;
        this.filteredDisputes = [...this.disputes];
        this.updatePage();
      },
      (error) => {
        console.error('Error fetching disputes', error);
        this.disputes = [];
        this.filteredDisputes = [];
        this.displayDisputes = [];
        this.updatePage();
      }
    );
  }

  searchDispute(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  applyFilters() {
    let tempDisputes = [...this.disputes];

    if (this.currentSearchText) {
      const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);
      tempDisputes = tempDisputes.filter(dispute => {
        const clientName = `${dispute.task_taken?.clients?.user?.first_name || ''} ${dispute.task_taken?.clients?.user?.middle_name || ''} ${dispute.task_taken?.clients?.user?.last_name || ''}`.trim().toLowerCase();
        const taskTitle = dispute.task_taken?.post_task?.task_title?.toLowerCase() || '';
        const reason = dispute.reason_for_dispute?.toLowerCase() || '';
        const details = dispute.dispute_details?.toLowerCase() || '';
        const disputeId = dispute.dispute_id?.toString() || '';

        return searchTerms.some(term => {
          return clientName.includes(term) || taskTitle.includes(term) || reason.includes(term) || details.includes(term) || disputeId.includes(term);
        });
      });
    }

    this.filteredDisputes = tempDisputes;
    this.updatePage();
  }

  viewDispute(dispute_id: number) {
    this.disputeService.getDisputeDetails(dispute_id).subscribe(
      (response: any) => {
        console.log('Dispute details:', response);
        this.disputes = response.disputes || []
      },
      (error) => {
        console.error('Error fetching dispute details', error);
        this.disputes = []
      }
    );
  }

  updateDispute(dispute_id: number, moderator_action: string, addl_dispute_notes: string, ) {
    this.disputeService.updateADispute(dispute_id, "Settled", moderator_action, addl_dispute_notes )
  }

  archiveDispute(dispute_id: number){
    this.disputeService.archiveADispute(dispute_id)
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredDisputes.length / this.logsPerPage);
    if (this.totalPages === 0) {
        this.totalPages = 1;
    }
    this.currentPage = Math.max(1, Math.min(this.currentPage, this.totalPages));

    const start = (this.currentPage - 1) * this.logsPerPage;
    const end = start + this.logsPerPage;
    this.displayDisputes = this.filteredDisputes.slice(start, end);
    this.startIndex = this.filteredDisputes.length === 0 ? 0 : start + 1;
    this.endIndex = Math.min(end, this.filteredDisputes.length);

    // Calculate the number of empty rows based on logsPerPage
    const placeholderCount = this.logsPerPage - this.displayDisputes.length;
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

    if (startPage > 1) {
      this.paginationButtons.push(1);
      if (startPage > 2) {
        this.paginationButtons.push('...');
      }
    }

    for (let i = startPage; i <= endPage; i++) {
      this.paginationButtons.push(i);
    }

    if (endPage < this.totalPages) {
      if (endPage < this.totalPages - 1) {
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

  changePage(page: number) {
    this.currentPage = page;
    this.updatePage();
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.updatePage();
    }
  }

  previousPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.updatePage();
    }
  }

  goToPage(page: string | number) {
    const pageNumber = Number(page);
    if (pageNumber >= 1 && pageNumber <= this.totalPages) {
      this.currentPage = pageNumber;
      this.updatePage();
    }
  }

  exportCSV() {
    // const headers = ['Dispute Id', 'Task Title', 'Reason for Dispute', 'Dispute Details', 'Raised By', 'Moderator Action', 'Created At'];
    // const rows = this.displayDisputes.map((disputes, index) => {
    //   const task_title = disputes.task_taken_
    //     ? `${disputes.tasker.user.first_name || ''} ${disputes.tasker.user.middle_name || ''} ${disputes.tasker.user.last_name || ''}`.trim()
    //     : '';
    //   const clientName = disputes.task_taken?.client?.user
    //     ? `${disputes.task_taken.client.user.first_name || ''} ${disputes.task_taken.client.user.middle_name || ''} ${disputes.task_taken.client.user.last_name || ''}`.trim()
    //     : '';
    //   const reported = disputes.reported ? disputes.reported : 'Empty';
    //   return [
    //     (this.currentPage - 1) * this.logsPerPage + index + 1,
    //     `"${taskerName}"`,
    //     `"${disputes.feedback || ''}"`,
    //     disputes.rating || '',
    //     `"${clientName}"`,
    //     `"${reported}"`,
    //     `"${disputes.created_at || ''}"`
    //   ];
    // });
    // const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    // const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    // saveAs(blob, 'NearbyTask_Disputes.csv');
  }

  exportPDF() {
    // const doc = new jsPDF({
    //   orientation: 'portrait',
    //   unit: 'px',
    //   format: 'a4',
    // });
    // const title = 'Feedback Management';
    // doc.setFontSize(20);
    // doc.text(title, 170, 45);
    // const headers = ['No', 'Tasker Name', 'Feedback', 'Rating', 'Client', 'Reported', 'Created At'];
    // const rows = this.displayFeedbacks.map((feedback, index) => {
    //   const taskerName = feedback.tasker?.user
    //     ? `${feedback.tasker.user.first_name || ''} ${feedback.tasker.user.middle_name || ''} ${feedback.tasker.user.last_name || ''}`.trim()
    //     : '';
    //   const clientName = feedback.task_taken?.client?.user
    //     ? `${feedback.task_taken.client.user.first_name || ''} ${feedback.task_taken.client.user.middle_name || ''} ${feedback.task_taken.client.user.last_name || ''}`.trim()
    //     : '';
    //   const reported = feedback.reported ? feedback.reported : 'Empty';
    //   return [
    //     (this.currentPage - 1) * this.logsPerPage + index + 1,
    //     taskerName,
    //     feedback.feedback || '',
    //     feedback.rating || '',
    //     clientName,
    //     reported,
    //     feedback.created_at || ''
    //   ];
    // });
    // autoTable(doc, {
    //   startY: 100,
    //   head: [headers],
    //   body: rows,
    //   theme: 'grid',
    //   styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
    //   headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    // });
    // doc.save('Feedbacks.pdf');
  }
}
