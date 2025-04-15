import { Component, OnInit } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';


@Component({
  selector: 'app-specialization',
  standalone: true,
  imports: [NgApexchartsModule, CommonModule],
  templateUrl: './specialization.component.html',
  styleUrls: ['./specialization.component.scss']
})
export class SpecializationComponent implements OnInit {
  rankedSpecializations: { specialization: string; total_requested: number; total_applied: number }[] = [];
  monthlyTrends: { [key: string]: { [key: string]: number } } = {};
  chartSeries: { name: string; data: number[] }[] = [];
  chartCategories: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchSpecializations();
  }

  fetchSpecializations(): void {
    this.reportService.getSpecialization('applied').subscribe({
      next: (response) => {
        if (response.success) {
          this.rankedSpecializations = response.rankedSpecializations;
          this.monthlyTrends = response.monthlyTrends;
          console.log("Ranked Specializations:", this.rankedSpecializations); // Debug
          this.updateChart();
        } else {
          console.error("Response unsuccessful:", response);
        }
      },
      error: (error: any) => {
        console.error('Error fetching specialization data:', error);
      }
    });
  }

  updateChart(): void {
    this.chartSeries = this.rankedSpecializations.map(spec => ({
      name: spec.specialization,
      data: this.chartCategories.map(month => this.monthlyTrends[spec.specialization]?.[month] || 0)
    }));
  }
}