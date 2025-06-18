import { Component, OnInit } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { SpecializationRank, MonthlyTrends, ChartSeries } from '../../../../../model/reportANDanalysis';

@Component({
  selector: 'app-specialization',
  standalone: true,
  imports: [NgApexchartsModule, CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './specialization.component.html',
  styleUrls: ['./specialization.component.scss']
})
export class SpecializationComponent implements OnInit {
  rankedSpecializations: SpecializationRank[] = [];
  monthlyTrends: MonthlyTrends = {};
  chartSeries: ChartSeries[] = [];
  chartCategories: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  selectedMonth: string | null = null;
  months: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  isDropdownOpen: boolean = false;
  isLoading: boolean = false;

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.isLoading = true;
    this.fetchSpecializations();
  }

  fetchSpecializations(): void {
    this.isLoading = true;
    this.reportService.getSpecialization('applied', this.selectedMonth || undefined).subscribe({
      next: (response) => {
        if (response.success) {
          // If a month is selected
          if (this.selectedMonth) {
            this.rankedSpecializations = response.rankedSpecializations.filter(spec => {
              const monthData = this.monthlyTrends[spec.specialization]?.[this.selectedMonth as string];
              return monthData && (Number(monthData) > 0 || spec.total_requested > 0 || spec.total_applied > 0);
            });
          } else {
            // If no month is selected
            this.rankedSpecializations = response.rankedSpecializations;
          }
        
          this.rankedSpecializations = this.rankedSpecializations.sort((a, b) => {
            if (b.total_applied !== a.total_applied) {
              return b.total_applied - a.total_applied;
            } else {
              return a.specialization.localeCompare(b.specialization);
            }
          });
          this.monthlyTrends = response.monthlyTrends;
          this.updateChart();
        }
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error fetching specialization data:', error);
        this.isLoading = false;
      }
    });
  }

  onMonthChange(): void {
    this.fetchSpecializations();
  }

  updateChart(): void {
    // Always show all months label
    this.chartCategories = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    if (this.selectedMonth) {
      // When a specific month is selected
      this.chartSeries = this.rankedSpecializations.map(spec => ({
        name: spec.specialization,
        data: this.chartCategories.map(month => 
          month === this.selectedMonth ? Math.floor(Number(this.monthlyTrends[spec.specialization]?.[month] || 0)) : 0
        )
      }));
    } else {
      // When all Months is selected
      this.chartSeries = this.rankedSpecializations.map(spec => ({
        name: spec.specialization,
        data: this.chartCategories.map(month => Math.floor(Number(this.monthlyTrends[spec.specialization]?.[month] || 0)))
      }));
    }
  }

  tooltipFormatter(val: number): string {
    return Math.floor(val).toString();
  }

  toggleDropdown(): void {
    this.isDropdownOpen = !this.isDropdownOpen;
  }

  exportCSV(): void {
    const headers = ['No', 'Specialization', 'Total Requested', 'Total Applied'];
    const rows = this.rankedSpecializations.map((spec, index) => [
      index + 1,
      `"${spec.specialization}"`,
      spec.total_requested,
      spec.total_applied
    ]);
    const csvContent = [headers.join(','), ...rows.map(row => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'Specializations.csv');
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

    // Specialization
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('Top Specialization', 30, 90);

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

    const headers = [' Analysis', 'Total Requested', 'Total Applied'];
    const rows = this.rankedSpecializations.map((spec, index) => [
      index + 1,
      spec.specialization,
      spec.total_requested,
      spec.total_applied
    ]);
    autoTable(doc, {
      startY: 125,
      head: [headers],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('Specializations.pdf');
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
      link.download = 'Specialization_Chart.png';
      link.click();
      this.isDropdownOpen = false;
    };

    img.onerror = (err) => {
      console.error('Error exporting PNG: Failed to load SVG image', err);
    };
  }
}