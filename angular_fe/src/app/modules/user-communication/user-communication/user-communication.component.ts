import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { UserConversationService } from 'src/app/services/conversation.service';
import Swal from 'sweetalert2';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';

@Component({
  selector: 'app-user-communication',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './user-communication.component.html',
  styleUrls: ['./user-communication.component.css'],
})
export class UserCommunicationComponent implements OnInit, OnDestroy {
  conversation: any[] = [];
  filteredConversations: any[] = [];
  displayConversations: any[] = [];
  placeholderRows: any[] = []; 
  paginationButtons: (number | string)[] = [];
  conversationsPerPage: number = 10;
  currentPage: number = 1;
  totalPages: number = 1;
  startIndex: number = 1;
  endIndex: number = 0;
  currentSearchText: string = '';
  currentReportedFilter: string = '';
  currentStatusFilter: string = '';

  private conversationSubscription!: Subscription;

  constructor(
    private userConversationService: UserConversationService,
  ) {}

  ngOnInit(): void {
    this.conversationSubscription = this.userConversationService.getUserConversation().subscribe(
      (response) => {
        console.log('Raw response:', response);
        if (response && response.data) {
          this.conversation = response.data;
          this.filteredConversations = [...this.conversation];
          this.updatePage();
          console.log('Processed conversation data:', this.conversation);
        } else {
          console.error('Invalid response format:', response);
        }
      },
      (error) => {
        console.error("Error getting logs:", error);
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

  // Apply all filters
  applyFilters() {
    let tempConversations = [...this.conversation];

    // Apply search filter
    if (this.currentSearchText) {
      tempConversations = tempConversations.filter(convo => {
        const fullName = `${convo.user.first_name || ''} ${convo.user.middle_name || ''} ${convo.user.last_name || ''}`.toLowerCase();
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
        const convoStatus = convo.user.status ? 'active' : 'disabled';
        return convoStatus === this.currentStatusFilter;
      });
    }

    this.filteredConversations = tempConversations;
    this.currentPage = 1;
    this.updatePage();
  }

  // Update the displayed conversations based on pagination
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

  banUser(id: number): void {
    Swal.fire({
      title: 'Are you sure to ban?',
      text: 'This action cannot be undone!',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, ban it!',
    }).then((result) => {
      if (result.isConfirmed) {
        this.userConversationService.banUser(id).subscribe((response) => {
          if (response) {
            Swal.fire('Banned!', 'User has been banned.', 'success').then(() => {
              // Refresh the conversation list after banning
              this.userConversationService.getUserConversation().subscribe((response) => {
                if (response && response.data) {
                  this.conversation = response.data;
                  this.filteredConversations = [...this.conversation];
                  this.updatePage();
                }
              });
            });
          }
        }, (error) => {
          Swal.fire('Error!', 'Failed to ban the user.', 'error');
        });
      }
    });
  }

  warnUser(id: number): void {
    Swal.fire({
      title: 'Are you sure to warn this user?',
      text: 'This action cannot be undone!',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, warn it!',
    }).then((result) => {
      if (result.isConfirmed) {
        this.userConversationService.warnUser(id).subscribe((response) => {
          if (response) {
            Swal.fire('Warned!', 'User has been warned.', 'success').then(() => {
              // Refresh the conversation list after warning
              this.userConversationService.getUserConversation().subscribe((response) => {
                if (response && response.data) {
                  this.conversation = response.data;
                  this.filteredConversations = [...this.conversation];
                  this.updatePage();
                }
              });
            });
          }
        }, (error) => {
          Swal.fire('Error!', 'Failed to warn the user.', 'error');
        });
      }
    });
  }

  viewConversation(taskTakenId: number, viewingUserId: number): void {
    console.log('Viewing conversation for task_taken_id:', taskTakenId);
    console.log('Viewing user_id:', viewingUserId);

    this.userConversationService.getTaskConversations(taskTakenId).subscribe(
        (response) => {
            if (response && response.data) {
                const messages = response.data;
                console.log('Messages received:', messages);

                const messagesHtml = messages.map((msg: any) => {
                    const messageUserId = Number(msg.user_id);
                    // Message is from the user whose conversation we're viewing
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
                    customClass: {
                        htmlContainer: 'text-left'
                    },
                    didOpen: () => {
                        const container = document.querySelector('.swal2-html-container > div');
                        if (container) {
                            container.scrollTop = container.scrollHeight;
                        }
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
        `"${convo.conversation || ''}"`, // Wrap in quotes to handle commas in conversation
        `"${convo.task_taken.created_at || ''}"`, // Wrap in quotes to handle commas in date
        convo.task_taken.task_status || '',
      ];
      console.log('CSV Row:', row); // Debug log to verify data
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
    const title = 'User Conversations';
    doc.setFontSize(20);
    doc.text(title, 170, 45);
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
      startY: 100,
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('UserConversations.pdf');
  }
}