import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { UserLogService } from 'src/app/services/log.service';

@Component({
  selector: 'app-log',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './log.component.html',
  styleUrl: './log.component.css',
})
export class LogComponent implements OnInit, OnDestroy {
  displayuserLogs: any[] = [];
  private logsSubscription!: Subscription; 

  constructor(private userlogService: UserLogService) {}

  ngOnInit(): void {
    this.logsSubscription = this.userlogService.getUserLogs().subscribe(
      (logs) => {
        this.displayuserLogs = logs;
      },
      (error) => {
        console.error("Error fetching logs:", error);
      }
    );
  }

  ngOnDestroy(): void {
    if (this.logsSubscription) {
      this.logsSubscription.unsubscribe();
    }
  }
  
}
