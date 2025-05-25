import { Component } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DisputeManagementService } from 'src/app/services/dispute-management.service';


import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import Swal from 'sweetalert2';


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
  paginationButtons: (number | string)[] = [];
  placeholderRows: any[] = []; // Added for placeholder rows
  disputeDetails: any = null
  selectedAction: string = '';
  additionalNotes: string = '';
  isLoading: boolean = true;
  constructor(private disputeService: DisputeManagementService) { }

  ngOnInit(): void {
    this.isLoading = true;
    this.disputeService.getAllDisputes().subscribe(
      (response: any) => {
        console.log('Received dispute data:', response);
        this.disputes = response.data || [];
        this.filteredDisputes = [...this.disputes];
        this.updatePage();
        this.isLoading = false;
      },
      (error) => {
        console.error('Error fetching disputes', error);
        this.disputes = [];
        this.filteredDisputes = [];
        this.displayDisputes = [];
        this.updatePage();
        this.isLoading = false;
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
    this.disputeDetails = this.filteredDisputes.find(dispute => dispute.dispute_id === dispute_id);
    if (!this.disputeDetails) {
      Swal.fire('Error', 'Dispute Information Cannot be Displayed', 'error');
      return;
    }

    const htmlContent = `
      <div class="p-6 bg-white rounded-lg shadow-md text-left">
        <!-- Warning Note Section -->
        ${!this.disputeDetails.moderator_action ? `
        <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-6">
          <div class="flex">
          <div class="ml-3">
            <h3 class="text-yellow-800 font-medium">Note to Moderator</h3>
            <p class="text-yellow-700 text-sm mt-2">
            PLEASE review all data such as: Task Information, Chat History, and User Reports before you settle this dispute.
            Additionally, you MUST contact BOTH the client and tasker and LISTEN to their dispute.
            </p>
          </div>
        </div>
      </div>
      ` : ''}
      <!-- Task Information Section -->
      <div class="grid grid-cols-1 gap-4 mb-6">
      <div class="border-b pb-4">
      <h3 class="text-lg font-semibold mb-4">Task Information</h3>
      <div class="space-y-3">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
        <strong class="text-gray-700">Task Title:</strong>
        <span class="text-gray-600 sm:col-span-2">${this.disputeDetails.task_taken?.post_task?.task_title || 'N/A'}</span>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
        <strong class="text-gray-700">Reason for Dispute:</strong>
        <span class="text-gray-600 sm:col-span-2">${this.disputeDetails.reason_for_dispute || 'N/A'}</span>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
        <strong class="text-gray-700">Dispute Details:</strong>
        <span class="text-gray-600 sm:col-span-2 text-sm">${this.disputeDetails.dispute_details || 'N/A'}</span>
        </div>
      </div>
      </div>

      <!-- Dispute Details Section -->
      <div class="border-b pb-4">
      <h3 class="text-lg font-semibold mb-4">Dispute Details</h3>
      <div class="space-y-3">
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
        <strong class="text-gray-700">Raised By:</strong>
        <span class="text-gray-600 sm:col-span-2">${this.disputeDetails.task_taken?.clients?.user?.first_name || 'N/A'} ${this.disputeDetails.task_taken?.clients?.user?.last_name || 'N/A'}</span>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
        <strong class="text-gray-700">Moderator Action:</strong>
        <span class="text-gray-600 sm:col-span-2">${this.disputeDetails.moderator_action || 'No Moderator Action'}</span>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
        <strong class="text-gray-700">Date Dispute was Raised:</strong>
        <span class="text-gray-600 sm:col-span-2">${this.disputeDetails.created_at || 'N/A'}</span>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
        <strong class="text-gray-700">Dispute Pictures:</strong>
        <div class="sm:col-span-2 flex flex-wrap gap-2">
          ${Array.isArray(this.disputeDetails.image_proof) && this.disputeDetails.image_proof.length > 0 ?
        this.disputeDetails.image_proof.map((pic: any) => `
            <img
            src="${pic}"
            alt="Dispute evidence"
            class="w-24 h-24 object-cover cursor-pointer rounded"
            onclick="window.open('${pic}', '_blank')"
            />`
        ).join('') :
        '<span class="text-gray-600">No pictures available</span>'
      }
        </div>
        </div>
      </div>
      </div>
      </div>

      <!-- Action Form Section -->
      ${!this.disputeDetails.moderator_action ? `
      <div class="space-y-4">
        <div class="form-group">
        <label for="moderatorAction" class="block text-gray-700 font-medium mb-2">Moderator Action:</label>
        <select id="moderatorAction" class="w-full p-2 border border-gray-300 rounded-md shadow-sm" required>
          <option value="">Select an action</option>
          <option value="refund_tokens">Refund NearByTask Tokens to Client</option>
          <option value="release_half">Release Half of the Total Payment to Tasker</option>
          <option value="release_full">Release Full Payment to Tasker</option>
          <option value="reject_dispute">Reject the Dispute</option>
        </select>
        </div>
        <div class="form-group">
        <label for="disputeNotes" class="block text-gray-700 font-medium mb-2">Additional Notes:</label>
        <textarea id="disputeNotes" class="w-full p-2 border border-gray-300 rounded-md shadow-sm" rows="3" required></textarea>
        </div>
      </div>
      ` : ''}
      </div>
    `;

    Swal.fire({
      title: "Dispute Details",
      html: htmlContent,
      width: '800px',
      showCancelButton: true,
      confirmButtonText: this.disputeDetails.moderator_action ? undefined : 'Update Dispute',
      showConfirmButton: !this.disputeDetails.moderator_action,
      confirmButtonColor: '#3085d6',
      cancelButtonText: 'Close',
      cancelButtonColor: '#d33',
      customClass: {
      htmlContainer: 'text-left'
      },
      preConfirm: () => {
      if (!this.disputeDetails.moderator_action) {
        const action = document.getElementById('moderatorAction') as HTMLSelectElement;
        const notes = document.getElementById('disputeNotes') as HTMLTextAreaElement;

        if (!action.value || !notes.value) {
        Swal.showValidationMessage('Please fill in all fields');
        return false;
        }

        return {
        action: action.value,
        notes: notes.value
        };
      }
      return false;
      }
    }).then((result) => {
      if (result.isConfirmed && result.value) {
      // Add confirmation modal
      Swal.fire({
        title: 'Are you sure?',
          cancelButtonText: 'Review the Dispute',
          confirmButtonColor: '#3085d6',
          cancelButtonColor: '#d33',
        }).then((confirmResult) => {
          if (confirmResult.isConfirmed) {
            this.updateDispute(
              this.disputeDetails.dispute_id,
              this.disputeDetails.task_taken.task_taken_id,
              this.disputeDetails.task_taken.post_task.task_id,
              result.value.action,
              result.value.notes
            );
          }
        });
      }
    });
  }

  updateDispute(dispute_id: number, task_taken_id: number, task_id: number, moderator_action: string, addl_dispute_notes: string,) {
    console.log("Updating a dispute with ID:", dispute_id);
    this.disputeService.updateADispute(dispute_id, task_taken_id, task_id, "Dispute Settled", moderator_action, addl_dispute_notes)
      .subscribe({
        next: (response) => {
          Swal.fire({
            title: "Successfully Updated Dispute",
            text: response.message,
            icon: 'success',
            confirmButtonColor: '#3085d6',
          })
          console.log('Dispute updated successfully:', response);
          this.ngOnInit();
        },
        error: (error) => {
          console.error('Error updating dispute:', error);
          Swal.fire({
            title: 'Error',
            text: 'Failed to update the dispute. Please try again.',
            icon: 'error',
            confirmButtonColor: '#3085d6',
          });
        }
      });
  }

  archiveDispute(dispute_id: number) {
    this.disputeDetails = this.filteredDisputes.find(dispute => dispute.dispute_id === dispute_id);
    if (!this.disputeDetails) {
      Swal.fire('Error', 'Dispute Information Cannot be Displayed', 'error');
      return;
    }

    if (!this.disputeDetails.moderator_action || this.disputeDetails.moderator_action === '') {
      Swal.fire({
        title: 'Error While Archiving A Dispute',
        text: 'This dispute cannot be archived because no moderator action has been taken yet.',
        icon: 'error',
        confirmButtonColor: '#3085d6',
      });
      return;
    }
    this.disputeService.archiveADispute(dispute_id).subscribe({
      next: (response) => {
        Swal.fire({
          title: "Successfully Archived Dispute",
          text: "Dispute Has Been Successfully Archived.",
          icon: 'success',
          confirmButtonColor: '#3085d6',
        })
        console.log('Dispute archived successfully:', response);
        this.ngOnInit();
      },
      error: (error) => {
        console.error('Error updating dispute:', error);
        Swal.fire({
          title: 'Error',
          text: 'Failed to update the dispute. Please try again.',
          icon: 'error',
          confirmButtonColor: '#3085d6',
        });
      }
    })
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
    const headers = ['ID', 'Task Title', 'Reason for Dispute', 'Dispute Details', 'Raised By', 'Moderator Action', 'Dispute Notes', 'Date Raised'];
    const rows = this.displayDisputes.map((disputes, index) => {
      const taskerName = disputes.task_taken_
        ? `${disputes.tasker.user.first_name || ''} ${disputes.tasker.user.middle_name || ''} ${disputes.tasker.user.last_name || ''}`.trim()
        : '';
      const clientName = disputes.task_taken?.client?.user
        ? `${disputes.task_taken.clients.user.first_name || ''} ${disputes.task_taken.clients.user.middle_name || ''} ${disputes.task_taken.clients.user.last_name || ''}`.trim()
        : '';
      return [
        (this.currentPage - 1) * this.logsPerPage + index + 1,
        `"${disputes.task_taken.post_task.task_title || ''}"`,
        disputes.reason_for_dispute || '',
        `"${disputes.dispute_details}"`,
        `"${clientName ?? taskerName}"`,
        `"${disputes.moderator_action}"`,
        `"${disputes.addl_dispute_notes}"`,
        `"${disputes.created_at || ''}"`
      ];
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'NearbyTask_Disputes.csv');
  }

  exportPDF() {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });
    const title = 'QTask Disputes';
    doc.setFontSize(20);
    doc.text(title, 170, 45);
    const headers = ['ID', 'Task Title', 'Reason for Dispute', 'Dispute Details', 'Raised By', 'Moderator Action', 'Dispute Notes', 'Date Raised'];
    const rows = this.displayDisputes.map((disputes, index) => {
      const taskerName = disputes.task_taken.clients?.user
        ? `${disputes.task_taken.tasker.user.first_name || ''} ${disputes.task_taken.tasker.user.middle_name || ''} ${disputes.task_taken.tasker.user.last_name || ''}`.trim()
        : '';
      const clientName = disputes.task_taken?.client?.user
        ? `${disputes.task_taken.clients.user.first_name || ''} ${disputes.task_taken.clients.user.middle_name || ''} ${disputes.task_taken.clients.user.last_name || ''}`.trim()
        : '';
      return [
        (this.currentPage - 1) * this.logsPerPage + index + 1,
        `"${disputes.task_taken.post_task.task_title || ''}"`,
        disputes.reason_for_dispute || '',
        `"${disputes.dispute_details}"`,
        `"${clientName ?? taskerName}"`,
        `"${disputes.moderator_action}"`,
        `"${disputes.addl_dispute_notes}"`,
        `"${disputes.created_at || ''}"`
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
    const today = new Date();
    const formattedDate = today.toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric'
    });
    doc.save(`QTask Disputes as of ${formattedDate}.pdf`);
  }
}
