import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { JobComponent } from "./job/job.component";
import { SpecializationComponent } from './specialization/specialization.component';
import { BestTaskerComponent } from "./best-tasker/best-tasker.component";
import { BestClientComponent } from "./best-client/best-client.component";
import { DepositorComponent } from './depositor/depositor.component';

@Component({
  selector: 'app-report',
  imports: [CommonModule,
    JobComponent,
    SpecializationComponent, 
    BestTaskerComponent, 
    BestClientComponent,
    DepositorComponent],
  templateUrl: './report.component.html',
  styleUrl: './report.component.css'
})
export class ReportComponent {

  currentTab: String ="MostFamousSpecialization";
  changeTab(option: String){
    this.currentTab = option;
  }
}