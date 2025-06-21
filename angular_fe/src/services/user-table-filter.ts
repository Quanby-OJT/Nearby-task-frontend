import { computed, Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class UserTableFilterService {
  searchField = signal<string>('');
  statusField = signal<string>('');
  orderField = signal<string>('');
  roleField = signal<string>('');
  onlineField = signal<string>('');
  pageSizeField = signal<number>(5);
  currentPageField = signal<number>(1);
  userSizeField = signal(0);
  reviewCount = signal<number>(0);

  private allUsers = signal<any[]>([]);
  currentUsers = signal<any[]>([]);

  // Computed signal for paginated users
  paginatedUsers = computed(() => {
    const start = (this.currentPageField() - 1) * this.pageSizeField();
    const end = start + this.pageSizeField();
    return this.allUsers().slice(start, end);
  });

  // Method to update all users
  setUsers(users: any[]) {
    this.allUsers.set(users);
    this.userSizeField.set(users.length);
    // Update review count
    this.reviewCount.set(users.filter(user => user.acc_status === 'Review').length);
  }

  setCurrentUsers(users: any[]) {
    this.currentUsers.set(users);
  }

  constructor() {}
}
