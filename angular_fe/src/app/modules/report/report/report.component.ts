import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { AnalysisComponent } from './analysis/analysis.component';
import { ReportsComponent } from "./reports/reports.component";

@Component({
  selector: 'app-report',
  imports: [CommonModule, AnalysisComponent, ReportsComponent],
  templateUrl: './report.component.html',
  styleUrl: './report.component.css'
})
export class ReportComponent {

  currentTab: String ="ReportTab";
  changeTab(option: String){
    this.currentTab = option;
  }
}