import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { UserConversationService } from 'src/app/services/conversation.service';
import Swal from 'sweetalert2';

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
    this.conversationSubscription = this.userConversationService.getUserLogs().subscribe(
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
              this.userConversationService.getUserLogs().subscribe((response) => {
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
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, warn it!', // Fixed the button text
    }).then((result) => {
      if (result.isConfirmed) {
        this.userConversationService.warnUser(id).subscribe((response) => { // Fixed to call warnUser
          if (response) {
            Swal.fire('Warned!', 'User has been warned.', 'success').then(() => { // Fixed the message
              // Refresh the conversation list after warning
              this.userConversationService.getUserLogs().subscribe((response) => {
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
}