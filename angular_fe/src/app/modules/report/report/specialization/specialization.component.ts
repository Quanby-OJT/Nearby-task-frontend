import { Component, OnInit } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: 'app-specialization',
  standalone: true,
  imports: [NgApexchartsModule, CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './specialization.component.html',
  styleUrls: ['./specialization.component.scss']
})
export class SpecializationComponent implements OnInit {
  rankedSpecializations: { specialization: string; total_requested: number; total_applied: number }[] = [];
  monthlyTrends: { [key: string]: { [key: string]: number } } = {};
  chartSeries: { name: string; data: number[] }[] = [];
  chartCategories: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  selectedMonth: string | null = null;
  months: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  isDropdownOpen: boolean = false;

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchSpecializations();
  }

  fetchSpecializations(): void {
    this.reportService.getSpecialization('applied', this.selectedMonth || undefined).subscribe({
      next: (response) => {
        if (response.success) {
          this.rankedSpecializations = response.rankedSpecializations;
          this.monthlyTrends = response.monthlyTrends;
          this.updateChart();
        }
      },
      error: (error) => {
        console.error('Error fetching specialization data:', error);
      }
    });
  }

  onMonthChange(): void {
    this.fetchSpecializations();
  }

  updateChart(): void {
    this.chartSeries = this.rankedSpecializations.map(spec => ({
      name: spec.specialization,
      data: this.chartCategories.map(month => this.monthlyTrends[spec.specialization]?.[month] || 0)
    }));
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
  
      doc.addImage('./assets/icons/heroicons/outline/NearbTask.png', 'PNG', 43, 27, 40, 40); 
    } catch (e) {
      console.error('Failed to load NearbyTasks.png:', e);

    }

    try {
      doc.addImage('./assets/icons/heroicons/outline/Quanby.png', 'PNG', 10, 25, 40, 40);
    } catch (e) {
      console.error('Failed to load Quanby.png:', e);

    }

    const title = 'Top Applied Specializations';
    doc.setFontSize(20);
    doc.text(title, 88, 50);
    const headers = ['No', 'Specialization', 'Total Requested', 'Total Applied'];
    const rows = this.rankedSpecializations.map((spec, index) => [
      index + 1,
      spec.specialization,
      spec.total_requested,
      spec.total_applied
    ]);
    autoTable(doc, {
      startY: 100,
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