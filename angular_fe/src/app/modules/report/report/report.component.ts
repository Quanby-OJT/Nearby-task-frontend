import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { JobComponent } from "./job/job.component";
import { SpecializationComponent } from './specialization/specialization.component';
import { BestTaskerComponent } from "./best-tasker/best-tasker.component";
import { BestClientComponent } from "./best-client/best-client.component";
import { DepositorComponent } from './depositor/depositor.component';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { LoadingService } from 'src/app/services/loading.service';

@Component({
  selector: 'app-report',
  standalone: true,
  imports: [
    CommonModule,
    JobComponent,
    SpecializationComponent, 
    BestTaskerComponent, 
    BestClientComponent,
    DepositorComponent,
    AngularSvgIconModule
  ],
  templateUrl: './report.component.html',
  styleUrl: './report.component.css'
})
export class ReportComponent implements OnInit {
  currentTab: string = "MostFamousSpecialization";
  isLoading: boolean = false;

  constructor(private loadingService: LoadingService) {}

  ngOnInit(): void {
    this.loadingService.show();
    // Simulate initial data load
    setTimeout(() => {
      this.loadingService.hide();
    }, 1500);
  }

  changeTab(option: string) {
    this.isLoading = true;
    this.currentTab = option;
    // Simulate tab data load
    setTimeout(() => {
      this.isLoading = false;
    }, 1000);
  }
}