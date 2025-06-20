import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy, EventEmitter, Output } from '@angular/core';
import { Subscription } from 'rxjs';
import { UserConversationService } from 'src/app/services/conversation.service';
import { Conversation, Message } from 'src/model/user-communication'; 
import Swal from 'sweetalert2';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { AuthService } from 'src/app/services/auth.service';
import { LoadingService } from 'src/app/services/loading.service';

@Component({
  selector: 'app-user-communication',
  standalone: true,
  imports: [CommonModule, AngularSvgIconModule],
  templateUrl: './user-communication.component.html',
  styleUrls: ['./user-communication.component.css'],
})
export class UserCommunicationComponent implements OnInit, OnDestroy {
  conversation: Conversation[] = [];
  filteredConversations: Conversation[] = [];
  displayConversations: Conversation[] = [];
  placeholderRows: any[] = []; 
  paginationButtons: (number | string)[] = [];
  conversationsPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  currentReportedFilter: string = '';
  currentStatusFilter: string = '';
  clientSortMode: 'default' | 'asc' | 'desc' = 'default';
  taskerSortMode: 'default' | 'asc' | 'desc' = 'default';
  dateSortMode: 'default' | 'newestToOldest' | 'oldestToNewest' = 'default';
  viewedUserSortMode: 'default' | 'asc' | 'desc' = 'default';
  isLoading: boolean = true;
  userRole: string | undefined;
  @Output() onCheck = new EventEmitter<boolean>();

  private conversationSubscription!: Subscription;

  constructor(
    private userConversationService: UserConversationService,
    private sessionStorage: SessionLocalStorage,
    private authService: AuthService,
    private loadingService: LoadingService
  ) {}

  ngOnInit(): void {
    this.loadingService.show();
    this.isLoading = true;
    this.conversationSubscription = this.userConversationService.getUserConversation().subscribe(
      (response: { data: Conversation[] }) => {
        console.log('Raw response:', response);
        if (response && response.data) {
          this.conversation = response.data;
          this.applyFilters();
          console.log('Processed conversation data:', this.conversation);
        } else {
          console.error('Invalid response format:', response);
        }
        this.isLoading = false;
        this.loadingService.hide();
      },
      (error) => {
        console.error("Error getting logs:", error);
        this.isLoading = false;
        this.loadingService.hide();
      }
    );
    this.authService.userInformation().subscribe(
      (response: any) => {
        this.userRole = response.user.user_role;
        this.isLoading = false;
        this.loadingService.hide();
      },
      (error: any) => {
        console.error('Error fetching user role:', error);
        this.isLoading = false;
        this.loadingService.hide();
      }
    );
  }

  ngOnDestroy(): void {
    if (this.conversationSubscription) {
      this.conversationSubscription.unsubscribe();
    }
  }

  // Search functionality
  searchConversations(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  // Filter by reported status
  filterReported(event: Event) {
    this.currentReportedFilter = (event.target as HTMLSelectElement).value;
    this.applyFilters();
  }

  // Filter by user status
  filterStatus(event: Event) {
    this.currentStatusFilter = (event.target as HTMLSelectElement).value;
    this.applyFilters();
  }

  // Apply all filters and sorting
  applyFilters() {
    let tempConversations = [...this.conversation];

    // Apply search filter
    if (this.currentSearchText) {
      tempConversations = tempConversations.filter(convo => {
        const fullName = `${convo.user.first_name || ''} ${convo.user.middlename || ''} ${convo.user.last_name || ''}`.toLowerCase();
        const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);
        return searchTerms.every(term => fullName.includes(term));
      });
    }

    // Apply reported filter
    if (this.currentReportedFilter) {
      const reportedValue = this.currentReportedFilter === 'true';
      tempConversations = tempConversations.filter(convo => convo.reported === reportedValue);
    }

    // Apply status filter
    if (this.currentStatusFilter) {
      tempConversations = tempConversations.filter(convo => {
        const convoStatus = convo.task_taken.clients.user.status ? 'active' : 'disabled';
        return convoStatus === this.currentStatusFilter;
      });
    }

    // Apply sorting based on sort modes
    if (this.viewedUserSortMode !== 'default') {
      tempConversations.sort((a, b) => {
        const nameA = `${a.user.first_name || ''} ${a.user.middlename || ''} ${a.user.last_name || ''}`.toLowerCase();
        const nameB = `${b.user.first_name || ''} ${b.user.middlename || ''} ${b.user.last_name || ''}`.toLowerCase();
        if (this.viewedUserSortMode === 'asc') {
          return nameA.localeCompare(nameB);
        } else { // 'desc'
          return nameB.localeCompare(nameA);
        }
      });
    } else if (this.dateSortMode !== 'default') {
      tempConversations.sort((a, b) => {
        const dateA = new Date(a.task_taken.created_at || '1970-01-01').getTime();
        const dateB = new Date(b.task_taken.created_at || '1970-01-01').getTime();
        return this.dateSortMode === 'newestToOldest' ? dateB - dateA : dateA - dateB;
      });
    } else if (this.clientSortMode !== 'default') {
      tempConversations.sort((a, b) => {
        const nameA = `${a.task_taken.clients.user.first_name || ''} ${a.task_taken.clients.user.middle_name || ''} ${a.task_taken.clients.user.last_name || ''}`.toLowerCase();
        const nameB = `${b.task_taken.clients.user.first_name || ''} ${b.task_taken.clients.user.middle_name || ''} ${b.task_taken.clients.user.last_name || ''}`.toLowerCase();
        if (this.clientSortMode === 'asc') {
          return nameA.localeCompare(nameB);
        } else { // 'desc'
          return nameB.localeCompare(nameA);
        }
      });
    } else if (this.taskerSortMode !== 'default') {
      tempConversations.sort((a, b) => {
        const nameA = `${a.task_taken.tasker.user.first_name || ''} ${a.task_taken.tasker.user.middle_name || ''} ${a.task_taken.tasker.user.last_name || ''}`.toLowerCase();
        const nameB = `${b.task_taken.tasker.user.first_name || ''} ${b.task_taken.tasker.user.middle_name || ''} ${b.task_taken.tasker.user.last_name || ''}`.toLowerCase();
        if (this.taskerSortMode === 'asc') {
          return nameA.localeCompare(nameB);
        } else { // 'desc'
          return nameB.localeCompare(nameA);
        }
      });
    } else {
      // Default sort by created_at descending
      tempConversations.sort((a, b) => {
        const dateA = new Date(a.task_taken.created_at || '1970-01-01');
        const dateB = new Date(b.task_taken.created_at || '1970-01-01');
        return dateB.getTime() - dateA.getTime();
      });
    }

    this.filteredConversations = tempConversations;
    this.currentPage = 1;
    this.updatePage();
  }

  public toggle(event: Event) {
    const value = (event.target as HTMLInputElement).checked;
    this.onCheck.emit(value);
  }

  public toggleSort(column: 'client' | 'tasker' | 'date' | 'viewedUser') {
    if (column === 'client') {
      switch (this.clientSortMode) {
        case 'default':
          this.clientSortMode = 'asc';
          this.taskerSortMode = 'default'; // Reset tasker sort
          this.dateSortMode = 'default'; // Reset date sort
          this.viewedUserSortMode = 'default';
          break;
        case 'asc':
          this.clientSortMode = 'desc';
          break;
        case 'desc':
          this.clientSortMode = 'default';
          break;
      }
    } else if (column === 'tasker') {
      switch (this.taskerSortMode) {
        case 'default':
          this.taskerSortMode = 'asc';
          this.clientSortMode = 'default'; // Reset client sort
          this.dateSortMode = 'default'; // Reset date sort
          this.viewedUserSortMode = 'default';
          break;
        case 'asc':
          this.taskerSortMode = 'desc';
          break;
        case 'desc':
          this.taskerSortMode = 'default';
          break;
      }
    } else if (column === 'date') {
      switch (this.dateSortMode) {
        case 'default':
          this.dateSortMode = 'newestToOldest';
          this.clientSortMode = 'default'; // Reset client sort
          this.taskerSortMode = 'default'; // Reset tasker sort
          this.viewedUserSortMode = 'default';
          break;
        case 'newestToOldest':
          this.dateSortMode = 'oldestToNewest';
          break;
        case 'oldestToNewest':
          this.dateSortMode = 'default';
          break;
      }
    } else if (column === 'viewedUser') {
      switch (this.viewedUserSortMode) {
        case 'default':
          this.viewedUserSortMode = 'asc';
          this.clientSortMode = 'default';
          this.taskerSortMode = 'default';
          this.dateSortMode = 'default';
          break;
        case 'asc':
          this.viewedUserSortMode = 'desc';
          break;
        case 'desc':
          this.viewedUserSortMode = 'default';
          break;
      }
    }
    this.applyFilters();
  }

  updatePage() {
    this.totalPages = Math.ceil(this.filteredConversations.length / this.conversationsPerPage);
    this.displayConversations = this.filteredConversations.slice(
      (this.currentPage - 1) * this.conversationsPerPage,
      this.currentPage * this.conversationsPerPage
    );
    this.startIndex = (this.currentPage - 1) * this.conversationsPerPage + 1;
    this.endIndex = Math.min(this.currentPage * this.conversationsPerPage, this.filteredConversations.length);

    const placeholderCount = this.conversationsPerPage - this.displayConversations.length;
    this.placeholderRows = Array(placeholderCount).fill({});

    this.makePaginationButtons();
  }

  // Generate pagination buttons
  makePaginationButtons() {
    const maxButtons = 3;
    let start = Math.max(1, this.currentPage - 1);
    let end = Math.min(this.totalPages, start + maxButtons - 1);

    this.paginationButtons = [];

    for (let i = start; i <= end; i++) {
      this.paginationButtons.push(i);
    }
  }

  // Change number of conversations per page
  changeConversationsPerPage(event: Event) {
    this.conversationsPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
    this.currentPage = 1;
    this.updatePage();
  }

  // Navigate to a specific page
  goToPage(page: number | string) {
    const pageNum = typeof page === 'string' ? parseInt(page, 10) : page;
    if (pageNum >= 1 && pageNum <= this.totalPages) {
      this.currentPage = pageNum;
      this.updatePage();
    }
  }

  async banUser(id: number, taskTakenId: number): Promise<void> {
    // First check authorization with backend
    this.userConversationService.checkAuthorization(id, taskTakenId).subscribe({
      next: (response) => {
        // If authorized, show reason modal
        this.showBanReasonModal(id, taskTakenId);
      },
      error: (error) => {
        if (error.status === 403) {
          Swal.fire('Error!', error.error.error || 'You don\'t have authority to perform this action.', 'error');
        } else {
          Swal.fire('Error!', error.error.error || 'Failed to check authorization.', 'error');
        }
      }
    });
  }

  async warnUser(id: number, taskTakenId: number): Promise<void> {
    // First check authorization with backend
    this.userConversationService.checkAuthorization(id, taskTakenId).subscribe({
      next: (response) => {
        // If authorized, show reason modal
        this.showWarnReasonModal(id, taskTakenId);
      },
      error: (error) => {
        if (error.status === 403) {
          Swal.fire('Error!', error.error.error || 'You don\'t have authority to perform this action.', 'error');
        } else {
          Swal.fire('Error!', error.error.error || 'Failed to check authorization.', 'error');
        }
      }
    });
  }

  async appealUser(id: number, taskTakenId: number): Promise<void> {
    // First check authorization with backend
    this.userConversationService.checkAuthorization(id, taskTakenId).subscribe({
      next: (response) => {
        // If authorized, show reason modal
        this.showAppealReasonModal(id, taskTakenId);
      },
      error: (error) => {
        if (error.status === 403) {
          Swal.fire('Error!', error.error.error || 'You don\'t have authority to perform this action.', 'error');
        } else {
          Swal.fire('Error!', error.error.error || 'Failed to check authorization.', 'error');
        }
      }
    });
  }

  // Helper methods to show reason modals
  private async showBanReasonModal(id: number, taskTakenId: number): Promise<void> {
    const { value: reason } = await Swal.fire({
      title: 'Ban User',
      html: `
        <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for banning</label>
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
      this.userConversationService.banUser(id, taskTakenId, reason).subscribe({
        next: (response) => {
          if (response) {
            Swal.fire('Banned!', 'User has been banned.', 'success').then(() => {
              this.userConversationService.getUserConversation().subscribe((response: { data: Conversation[] }) => {
                if (response && response.data) {
                  this.conversation = response.data;
                  this.filteredConversations = [...this.conversation];
                  this.updatePage();
                }
              });
            });
          }
        },
        error: (error) => {
          Swal.fire('Error!', error.error.error || 'Failed to ban the user.', 'error');
        }
      });
    }
  }

  private async showWarnReasonModal(id: number, taskTakenId: number): Promise<void> {
    const { value: reason } = await Swal.fire({
      title: 'Warn User',
      html: `
        <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for warning</label>
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
      this.userConversationService.warnUser(id, taskTakenId, reason).subscribe({
        next: (response) => {
          if (response) {
            Swal.fire('Warned!', 'User has been warned.', 'success').then(() => {
              this.userConversationService.getUserConversation().subscribe((response: { data: Conversation[] }) => {
                if (response && response.data) {
                  this.conversation = response.data;
                  this.filteredConversations = [...this.conversation];
                  this.updatePage();
                }
              });
            });
          }
        },
        error: (error) => {
          Swal.fire('Error!', error.error.error || 'Failed to warn the user.', 'error');
        }
      });
    }
  }

  private async showAppealReasonModal(id: number, taskTakenId: number): Promise<void> {
    const { value: reason } = await Swal.fire({
      title: 'Appeal User',
      html: `
        <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for appealing</label>
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
      this.userConversationService.appealUser(id, taskTakenId, reason).subscribe({
        next: (response) => {
          if (response) {
            Swal.fire('Appealed!', 'User has been appealed.', 'success').then(() => {
              this.userConversationService.getUserConversation().subscribe((response: { data: Conversation[] }) => {
                if (response && response.data) {
                  this.conversation = response.data;
                  this.filteredConversations = [...this.conversation];
                  this.updatePage();
                }
              });
            });
          }
        },
        error: (error) => {
          Swal.fire('Error!', error.error.error || 'Failed to appeal the user.', 'error');
        }
      });
    }
  }

  viewConversation(taskTakenId: number, viewingUserId: number): void {
    console.log('Viewing conversation for task_taken_id:', taskTakenId);
    console.log('Viewing user_id:', viewingUserId);

    this.userConversationService.getTaskConversations(taskTakenId).subscribe(
      (response: { data: Message[] }) => {
        if (response && response.data) {
          const messages = response.data;
          console.log('Messages received:', messages);

          const messagesHtml = messages.map((msg: Message) => {
            const messageUserId = Number(msg.user_id);
            const isViewingUser = messageUserId === viewingUserId;
            console.log(`Message User ID: ${messageUserId}, Viewing User ID: ${viewingUserId}, isViewingUser: ${isViewingUser}`);

            const alignment = isViewingUser ? 'right' : 'left';
            const bgColor = isViewingUser ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-800';
            const margin = isViewingUser ? 'ml-auto' : 'mr-auto';
            const roundedCorners = isViewingUser ? 'rounded-tl-lg rounded-bl-lg rounded-br-lg' : 'rounded-tr-lg rounded-br-lg rounded-bl-lg';

            const userName = msg.user
              ? `${msg.user.first_name || ''} ${msg.user.middle_name || ''} ${msg.user.last_name || ''}`.trim()
              : 'Unknown User';

            const timestamp = msg.created_at || 'No Timestamp';

            return `
              <div class="flex justify-${alignment} mb-4">
                <div class="${margin} max-w-[70%]">
                  <div class="font-semibold text-sm mb-1 ${alignment === 'right' ? 'text-right' : 'text-left'}">
                    ${userName}
                  </div>
                  <div class="${bgColor} ${roundedCorners} px-4 py-2 text-justify">
                    ${msg.conversation}
                  </div>
                  <div class="text-xs text-gray-500 mt-1 ${alignment === 'right' ? 'text-right' : 'text-left'}">
                    ${timestamp}
                  </div>
                </div>
              </div>`;
          }).join('');

          const html = `
            <div style="max-height: 400px; overflow-y: auto; padding-right: 10px;">
              ${messagesHtml}
            </div>
          `;
          Swal.fire({
            title: 'Users Conversation',
            html: html,
            width: '800px',
            confirmButtonText: 'Close',
            confirmButtonColor: '#3085d6',
            showCancelButton: false,
            customClass: {
              htmlContainer: 'text-left',
              actions: 'swal2-actions-right'
            },
            didOpen: () => {
              const container = document.querySelector('.swal2-html-container > div');
              if (container) {
                container.scrollTop = container.scrollHeight;
              }
              // Add custom CSS to ensure right alignment
              const style = document.createElement('style');
              style.textContent = `
                .swal2-actions-right {
                  display: flex !important;
                  justify-content: flex-end !important;
                  width: 100% !important;
                  padding-right: 20px !important;
                }
              `;
              document.head.appendChild(style);
            }
          });
        } else {
          Swal.fire('Error', 'No messages found', 'error');
        }
      },
      (error) => {
        Swal.fire('Error', 'Failed to load conversation', 'error');
      }
    );
  }

  exportCSV() {
    const headers = ['User No', 'Client Name', 'Tasker Name', 'Conversation', 'Task Created Date', 'Task Status'];
    const rows = this.displayConversations.map((convo) => {
      const row = [
        convo.user_id ?? '',
        `"${convo.task_taken.clients.user.first_name} ${convo.task_taken.clients.user.middle_name || ''} ${convo.task_taken.clients.user.last_name}"`,
        `"${convo.task_taken.tasker.user.first_name} ${convo.task_taken.tasker.user.middle_name || ''} ${convo.task_taken.tasker.user.last_name}"`,
        `"${convo.conversation || ''}"`,
       `"${convo.task_taken.created_at || ''}"`,
        convo.task_taken.task_status || '',
      ];
      console.log('CSV Row:', row);
      return row;
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'UserConversations.csv');
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

    // User Conversation
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('User Conversation', 30, 90);

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

    const columns = ['User No', 'Client Name', 'Tasker Name', 'Conversation', 'Task Created Date', 'Task Status'];
    const rows = this.displayConversations.map((convo) => [
      convo.user_id ?? '',
      `${convo.task_taken.clients.user.first_name} ${convo.task_taken.clients.user.middle_name || ''} ${convo.task_taken.clients.user.last_name}`,
      `${convo.task_taken.tasker.user.first_name} ${convo.task_taken.tasker.user.middle_name || ''} ${convo.task_taken.tasker.user.last_name}`,
      convo.conversation || '',
      convo.task_taken.created_at || '',
      convo.task_taken.task_status || '',
    ]);
    autoTable(doc, {
      startY: 125,
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('UserConversations.pdf');
  }
}