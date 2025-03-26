import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ClientComplaintComponent } from './client-complaint/client-complaint.component';
import { TaskerComplaintComponent } from './tasker-complaint/tasker-complaint.component';
import { ReportService } from 'src/app/services/report.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-complaints',
  standalone: true,
  imports: [
    CommonModule,
    ClientComplaintComponent,
    TaskerComplaintComponent
  ],
  templateUrl: './complaints.component.html',
  styleUrls: ['./complaints.component.css']
})
export class ComplaintsComponent implements OnInit{

  reports: any[] = [];
  

  private reportsSubscription!: Subscription;

  constructor(
    private reportService: ReportService
  ){}

  ngOnInit(): void {
    this.reportsSubscription = this.reportService.getReport().subscribe(
      (response) => {
        if (response.success){
          this.reports = response.reports;
        }
      },
      (errors) => {
        console.error("Failed in getting reports: ", errors);
      }
    );
  }

  ngOnDestroy(): void{
    if(this.reportsSubscription){
      this.reportsSubscription.unsubscribe();
    }
  }
}