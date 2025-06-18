import { computed, Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class ComplaintsFilterService {
  searchField = signal<string>('');
  statusField = signal<string>('');
  orderField = signal<string>('');
  pageSizeField = signal<number>(5);
  currentPageField = signal<number>(1);
  complaintsSizeField = signal(0);
  pendingCount = signal<number>(0);

  private allComplaints = signal<any[]>([]);
  currentComplaints = signal<any[]>([]);

  // Computed signal for paginated complaints
  paginatedComplaints = computed(() => {
    const start = (this.currentPageField() - 1) * this.pageSizeField();
    const end = start + this.pageSizeField();
    return this.allComplaints().slice(start, end);
  });

  // Method to update all complaints
  setComplaints(complaints: any[]) {
    this.allComplaints.set(complaints);
    this.complaintsSizeField.set(complaints.length);
    // Update pending count - count complaints where status is false (pending)
    this.pendingCount.set(complaints.filter(complaint => !complaint.status).length);
  }

  setCurrentComplaints(complaints: any[]) {
    this.currentComplaints.set(complaints);
  }

  constructor() {}
} 