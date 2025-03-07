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
  Math = Math;
  logs: any[] = [];
  filteredLogs: any[] = [];
  displayLogs: any[] = [];
  paginationButton: (number | string)[] = [];
  logsPerPage: number = 10;
  currentPage: number = 1;
  totalPages: number = 1;

  private logsSubscription!: Subscription; 

  constructor(private userlogService: UserLogService) {}

  ngOnInit(): void {
    this.logsSubscription = this.userlogService.getUserLogs().subscribe(
      (logs) => {
        this.displayLogs = logs;
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
  
    filterLogs(event: Event){
      // Gets the value from html <select> //
      const selectedValue = (event.target as HTMLSelectElement).value.toLowerCase();
      // filteredLogs now have the html value selected, with ternary operation //
      this.filteredLogs = selectedValue === "" ? this.logs : this.logs.filter(logs => logs.status?.toLowerCase() === selectedValue)
    this.currentPage = 1;
    this.updatePagination();
    }

    updatePagination(){
      this.totalPages = this.Math.ceil(this.filteredLogs.length / this.logsPerPage);
      this.displayLogs = this.filteredLogs.slice(
        (this.currentPage - 1) * this.logsPerPage
      );
      // Late For Geenrate //
    }

}
