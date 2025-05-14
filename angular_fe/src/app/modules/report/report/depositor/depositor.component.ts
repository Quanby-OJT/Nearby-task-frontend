import { Component, OnInit } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApexOptions, ApexAxisChartSeries, ApexChart, ApexXAxis, ApexStroke, ApexTitleSubtitle, ApexGrid, ApexLegend } from 'ng-apexcharts';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AngularSvgIconModule } from 'angular-svg-icon';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { Depositor, MonthlyTrends, ChartSeries } from '../../../../../model/reportANDanalysis';

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
  imports: [NgApexchartsModule, CommonModule, FormsModule, AngularSvgIconModule],
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

  depositors: Depositor[] = [];
  currentPage: number = 1;
  itemsPerPage: number = 10;
  totalItems: number = 0;
  selectedMonth: string | null = null;
  months: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  isDropdownOpen: boolean = false;
  isLoading: boolean = true;
  monthlyTrends: MonthlyTrends = {};

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchTopDepositors();
  }

  tooltipFormatter(val: number): string {
    return Math.floor(val).toString();
  }

  fetchTopDepositors(): void {
    this.reportService.getTopDepositors(this.selectedMonth || undefined).subscribe({
      next: (response: {
        success: boolean;
        rankedDepositors: Depositor[];
        monthlyTrends: MonthlyTrends;
      }) => {
        if (response.success) {
          this.depositors = response.rankedDepositors;
          this.monthlyTrends = response.monthlyTrends;
          this.totalItems = this.depositors.length;
          this.updateChart();
        }
        this.isLoading = false;
      },
      error: (error: unknown) => {
        console.error('Error fetching top depositors:', error);
        this.isLoading = false;
      },
    });
  }

  updateChart(): void {
    const categories = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const series: ChartSeries[] = Object.keys(this.monthlyTrends).map(userName => ({
      name: userName,
      data: this.selectedMonth
        ? categories.map(month => 
            month === this.selectedMonth ? Math.floor(Number(this.monthlyTrends[userName]?.[month] || 0)) : 0
          )
        : categories.map(month => Math.floor(Number(this.monthlyTrends[userName]?.[month] || 0)))
    }));

    this.chartOptions = {
      ...this.chartOptions,
      series: series
    };
  }

  onMonthChange(): void {
    this.fetchTopDepositors();
  }

  toggleDropdown(): void {
    this.isDropdownOpen = !this.isDropdownOpen;
  }

  exportCSV(): void {
    const headers = ['No', 'Depositor', 'Amount Deposited', 'Month Deposited'];
    const rows = this.depositors.map((depositor, index) => [
      index + 1,
      `"${depositor.userName}"`,
      depositor.amount,
      depositor.month
    ]);
    const csvContent = [headers.join(','), ...rows.map(row => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'Depositors.csv');
    this.isDropdownOpen = false;
  }

  exportPDF(): void {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });

    try {
      doc.addImage('./assets/icons/heroicons/outline/NearbTask.png', 'PNG', 140, 35, 28, 25); 
    } catch (e) {
      console.error('Failed to load NearbyTasks.png:', e);
    }

    try {
      doc.addImage('./assets/icons/heroicons/outline/Quanby.png', 'PNG', 260, 35, 26, 25);
    } catch (e) {
      console.error('Failed to load Quanby.png:', e);
    }

    // Nearby Task Part
    const title = 'Nearby Task';
    doc.setFontSize(20);
    doc.setTextColor('#170A66');
    doc.text(title, 170, 52);

    // Line Part
    doc.setDrawColor(0, 0, 0);
    doc.setLineWidth(0.2);
    doc.line(30, 70, 415, 70);

    // Depositor Part
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('Top Depositor', 30, 90);

    // Date and Time Part
    const currentDate = new Date();
    const formattedDate = currentDate.toLocaleString('en-US', {
      month: '2-digit',
      day: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    }).replace(/,/, ', ');
    console.log('Formatted Date:', formattedDate); 

    // Date and Time Position and Size
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    console.log('Rendering date at position x=400, y=90'); 
    doc.text(formattedDate, 310, 90); 

    const headers = ['No', 'Depositor', 'Amount Deposited', 'Month Deposited'];
    const rows = this.depositors.map((depositor, index) => [
      index + 1,
      depositor.userName,
      depositor.amount,
      depositor.month
    ]);
    autoTable(doc, {
      startY: 125,
      head: [headers],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('Depositors.pdf');
    this.isDropdownOpen = false;
  }

  exportPNG(): void {
    const chartElement = document.querySelector('#chart .apexcharts-svg') as SVGSVGElement;
    if (!chartElement) {
      console.error('Error exporting PNG: Chart SVG element not found');
      return;
    }

    console.log('Chart SVG found:', chartElement); // Debug log

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      console.error('Error exporting PNG: Canvas context not available');
      return;
    }

    const width = chartElement.width.baseVal.value || 800; // Fallback width
    const height = chartElement.height.baseVal.value || 400; // Fallback height
    canvas.width = width;
    canvas.height = height;

    // Set the canvas background to white to match the chart's background
    ctx.fillStyle = '#ffffff'; // White background
    ctx.fillRect(0, 0, width, height);

    const svgData = new XMLSerializer().serializeToString(chartElement);
    const img = new Image();
    img.src = 'data:image/svg+xml;base64,' + btoa(svgData);

    img.onload = () => {
      console.log('Image loaded for PNG export'); // Debug log
      ctx.drawImage(img, 0, 0, width, height);
      const imgURI = canvas.toDataURL('image/png');
      const link = document.createElement('a');
      link.href = imgURI;
      link.download = 'Depositor_Chart.png';
      link.click();
      this.isDropdownOpen = false;
    };

    img.onerror = (err) => {
      console.error('Error exporting PNG: Failed to load SVG image', err);
    };
  }

  get paginatedDepositors(): Depositor[] {
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