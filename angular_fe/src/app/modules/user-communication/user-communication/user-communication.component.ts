import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { UserConversationService } from 'src/app/services/conversation.service';

@Component({
  selector: 'app-user-communication',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './user-communication.component.html',
  styleUrls: ['./user-communication.component.css'],
})
export class UserCommunicationComponent implements OnInit, OnDestroy {
  conversation: any[] = [];

  private conversationSubscription!: Subscription;

  constructor(private userConversationService: UserConversationService) {
  }

  ngOnInit(): void {
    this.conversationSubscription = this.userConversationService.getUserLogs().subscribe(
      (response) => {
        console.log('Raw response:', response);
        if (response && response.data) {
          this.conversation = response.data;
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
}