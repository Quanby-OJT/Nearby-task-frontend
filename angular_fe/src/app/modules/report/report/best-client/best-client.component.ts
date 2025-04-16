import { Component, OnInit } from '@angular/core';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { CommonModule } from '@angular/common';
@Component({
  selector: 'app-best-client',
  imports: [CommonModule],
  templateUrl: './best-client.component.html',
  styleUrl: './best-client.component.css'
})
export class BestClientComponent implements OnInit {
  clients: { userName: string; address: string; taskCount: number; gender: string }[] = [];

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchClients();
  }

  fetchClients(): void {
    this.reportService.getTopClient().subscribe({
      next: (response) => {
        if (response.success) {
          this.clients = response.clients;
        }
      },
      error: (err) => {
        console.error('Error fetching clients:', err);
      }
    });
  }
}