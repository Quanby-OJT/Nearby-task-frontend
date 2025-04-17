import { Component, OnInit } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApexOptions, ApexAxisChartSeries, ApexChart, ApexXAxis, ApexStroke, ApexTitleSubtitle, ApexGrid, ApexLegend } from 'ng-apexcharts';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';

interface ChartConfig extends ApexOptions {
  series: ApexAxisChartSeries;
  chart: ApexChart;
  xaxis: ApexXAxis;
  stroke: ApexStroke;
  title: ApexTitleSubtitle;
  grid: ApexGrid;
  colors: string[];
  legend: ApexLegend;
}

@Component({
  selector: 'app-depositor',
  imports: [NgApexchartsModule, CommonModule],
  templateUrl: './depositor.component.html',
  styleUrl: './depositor.component.css',
  standalone: true,
  providers: [ReportService]
})
export class DepositorComponent implements OnInit {
  chartOptions: ChartConfig = {
    series: [] as ApexAxisChartSeries,
    chart: {
      type: 'area',
      height: 350,
      zoom: { enabled: false },
      toolbar: { show: false }
    } as ApexChart,
    xaxis: {
      categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      labels: { style: { colors: '#333' } }
    } as ApexXAxis,
    stroke: { 
      curve: 'smooth',
      width: 2
    } as ApexStroke,
    title: { 
      text: 'Monthly Deposit Trends', 
      align: 'left',
      style: { fontSize: '16px', fontWeight: 'bold' }
    } as ApexTitleSubtitle,
    grid: { 
      row: { 
        colors: ['#f3f3f3', 'transparent'], 
        opacity: 0.5 
      },
      borderColor: '#f1f1f1'
    } as ApexGrid,
    colors: ['#8586EC', '#4CAF50', '#FFC107', '#FF5722', '#2196F3'],
    legend: { 
      position: 'bottom',
      horizontalAlign: 'center'
    } as ApexLegend
  };

  depositors: { userName: string; amount: number; month: string }[] = [];
  currentPage: number = 1;
  itemsPerPage: number = 10;
  totalItems: number = 0;

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchTopDepositors();
  }

  fetchTopDepositors(): void {
    this.reportService.getTopDepositors().subscribe({
      next: (response: {
        success: boolean;
        rankedDepositors: { userName: string; amount: number; month: string }[];
        monthlyTrends: { [userName: string]: { [month: string]: number } };
      }) => {
        if (response.success) {
          this.depositors = response.rankedDepositors;
          this.totalItems = this.depositors.length;

          // Prepare chart series
          const monthlyTrends = response.monthlyTrends;
          const series: ApexAxisChartSeries = Object.keys(monthlyTrends).map(userName => ({
            name: userName,
            data: Object.values(monthlyTrends[userName]).map(value => value as number),
          }));

          this.chartOptions = {
            ...this.chartOptions,
            series: series
          };
        }
      },
      error: (error: unknown) => {
        console.error('Error fetching top depositors:', error);
      },
    });
  }

  get paginatedDepositors(): { userName: string; amount: number; month: string }[] {
    const startIndex = (this.currentPage - 1) * this.itemsPerPage;
    return this.depositors.slice(startIndex, startIndex + this.itemsPerPage);
  }

  changePage(page: number): void {
    if (page >= 1 && page <= Math.ceil(this.totalItems / this.itemsPerPage)) {
      this.currentPage = page;
    }
  }

  updateItemsPerPage(event: Event): void {
    const selectElement = event.target as HTMLSelectElement;
    this.itemsPerPage = parseInt(selectElement.value, 10);
    this.currentPage = 1;
  }

  get totalPages(): number {
    return Math.ceil(this.totalItems / this.itemsPerPage);
  }
}