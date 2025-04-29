import { Component } from '@angular/core';
import { DisputeTableComponent } from './dispute-table/dispute-table.component';


import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-dispute-management',
  standalone: true,
  imports: [DisputeTableComponent],
  templateUrl: './dispute-management.component.html',
  styleUrl: './dispute-management.component.css'
})
export class DisputeManagementComponent {
}
