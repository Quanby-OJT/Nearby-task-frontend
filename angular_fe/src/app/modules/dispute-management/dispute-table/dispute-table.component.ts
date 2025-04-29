import { Component,  } from '@angular/core';
import { DisputeSearchComponent } from '../dispute-search/dispute-search.component';
import { DisputeFilterComponent } from '../dispute-filter/dispute-filter.component';
import { DisputeManagementService } from 'src/app/services/dispute-management.service';
import { AngularSvgIconModule } from 'angular-svg-icon';
import saveAs from 'file-saver';

@Component({
  selector: 'app-dispute-table',
  imports: [DisputeFilterComponent, DisputeSearchComponent, AngularSvgIconModule],
  standalone: true,
  templateUrl: './dispute-table.component.html',
  styleUrl: './dispute-table.component.css'
})
export class DisputeTableComponent {
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

  constructor(private disputeService: DisputeManagementService) {}

  ngOnInit(): void {
    this.disputeService.getAllDisputes().subscribe(
      (response: any) => {
        console.log('Received dispute data:', response);
        this.disputes = response.disputes || [];
        this.displayDisputes = this.disputes || []
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
        const taskerName = dispute.tasker?.user?.first_name?.toLowerCase() || '';
        const taskStatus = dispute.task_status?.toLowerCase() || '';
        const taskId = dispute.task_id?.toString() || '';

        return searchTerms.some(term => {
          return taskerName.includes(term) || taskStatus.includes(term) || taskId.includes(term);
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

  updateDispute(dispute_id: number, moderator_action: String) {

  }

  archiveDispute(dispute_id: number){

  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredDisputes.length / this.logsPerPage);
    this.startIndex = (this.currentPage - 1) * this.logsPerPage + 1;
    this.endIndex = Math.min(this.startIndex + this.logsPerPage - 1, this.filteredDisputes.length);
    this.displayDisputes = this.filteredDisputes.slice((this.currentPage - 1) * this.logsPerPage, this.currentPage * this.logsPerPage);

    // Update pagination buttons
    const maxButtons = 5; // Maximum number of pagination buttons to show
    const halfMaxButtons = Math.floor(maxButtons / 2);
    let startButton = Math.max(1, this.currentPage - halfMaxButtons);
    let endButton = Math.min(this.totalPages, startButton + maxButtons - 1);

    if (endButton - startButton < maxButtons - 1) {
      startButton = Math.max(1, endButton - maxButtons + 1);
    }

    this.paginationButtons = Array.from({ length: endButton - startButton + 1 }, (_, i) => startButton + i);
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

  goToPage(page: number) {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
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
