import { HttpClient } from '@angular/common/http';
import { Component, effect, ElementRef, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { toast } from 'ngx-sonner';
import { UserTableActionComponent } from '../table/table-action/table-action.component';
import { UserTableFooterComponent } from '../table/table-footer/table-footer.component';
import { UserTableHeaderComponent } from '../table/table-header/table-header.component';
import { UserTableRowComponent } from '../table/table-row/table-row.component';
import { Router } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';
import { UserTableFilterService } from 'src/services/user-table-filter';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { CommonModule, NgIf } from '@angular/common';
import { saveAs } from 'file-saver';
import { AuthService } from 'src/app/services/auth.service';
import { LoadingService } from 'src/app/services/loading.service';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [
    AngularSvgIconModule,
    FormsModule,
    UserTableHeaderComponent,
    UserTableFooterComponent,
    UserTableRowComponent,
    UserTableActionComponent,
    CommonModule
  ],
  templateUrl: './users.component.html',
  styleUrls: ['./users.component.css'],
})
export class UsersComponent implements OnInit {
  @ViewChild('table', { static: false }) table!: ElementRef;
  public users: any[] = [];
  public PaginationUsers: any[] = [];
  displayedUsers = this.filterService.currentUsers;
  selectedUserId: Number | null = null;
  profileSortState: 'default' | 'asc' | 'desc' = 'default';
  emailSortState: 'default' | 'asc' | 'desc' = 'default';
  activeSortColumn: 'profile' | 'email' | null = null;
  isLoading: boolean = true;
  userRole: string | undefined;

  constructor(
    private http: HttpClient,
    public filterService: UserTableFilterService,
    private router: Router,
    private useraccount: UserAccountService,
    private authService: AuthService,
    private loadingService: LoadingService
  ) {
    effect(() => {
      const currentPage = this.filterService.currentPageField();
      const pageSize = this.filterService.pageSizeField();
      const filteredUsers = this.filteredUsers;
      const totalFilteredUsers = filteredUsers.length;
      const totalPages = Math.ceil(totalFilteredUsers / pageSize) || 1;

      if (currentPage > totalPages) {
        this.filterService.currentPageField.set(totalPages);
      }

      const startIndex = (currentPage - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedUsers = filteredUsers.slice(startIndex, endIndex);
      this.filterService.setCurrentUsers(paginatedUsers);
    });
  }

  ngOnInit(): void {
    this.loadingService.show();
    this.isLoading = true;
    this.fetchUsers();
    this.setUserSize();
    this.authService.userInformation().subscribe(
      (response: any) => {
        this.userRole = response.user.user_role;
        this.isLoading = false;
        this.loadingService.hide();
      },
      (error: any) => {
        console.error('Error fetching user role:', error);
        this.isLoading = false;
        this.loadingService.hide();
      }
    );
  }

  exportCSV() {
    const headers = ['Fullname', 'Role', 'Email', 'Account', 'Status'];
    const rows = this.filterService.currentUsers().map((item) => [
      `"${item.first_name} ${item.middle_name === null ? '' : item.middle_name} ${item.last_name}"`,
      item.user_role,
      item.email,
      item.acc_status,
      item.status,
    ]);
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'UserAccounts.csv');
  }

  exportPDF() {
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

    //User Management
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('User Managment', 30, 90);

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

    const columns = ['Fullname', 'Role', 'Email', 'Account', 'Status'];
    const rows = this.filterService.currentUsers().map((item) => [
      item.first_name + ' ' + (item.middle_name === null ? '' : item.middle_name) + ' ' + item.last_name,
      item.user_role,
      item.email,
      item.acc_status,
      item.status,
    ]);
    autoTable(doc, {
      startY: 125,
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });

    doc.save('UserAccounts.pdf');
  }

  setUserSize(): void {
    this.useraccount.getAllUsers().subscribe((response) => {
      this.filterService.setUsers(this.users);
    });
  }

  get UserSize(): number {
    return this.filteredUsers.length;
  }

  fetchUsers(): void {
    this.useraccount.getAllUsers().subscribe(
      (response: any) => {
        this.users = response.users;
        this.filterService.setUsers(this.users);
        const pageSize = this.filterService.pageSizeField();
        this.filterService.setCurrentUsers(this.filteredUsers.slice(0, pageSize));
        this.isLoading = false;
        this.loadingService.hide();
      },
      (error: any) => {
        console.error('Error fetching users:', error);
        this.handleRequestError(error);
        this.isLoading = false;
        this.loadingService.hide();
      },
    );
  }

  get filteredUsers(): any[] {
    const search = this.filterService.searchField().toLowerCase() || '';
    const account = this.filterService.statusField();
    const status = this.filterService.onlineField();
    const role = this.filterService.roleField();

    let filtered = this.users.filter((user) => {
      const firstName = String(user.first_name || '').toLowerCase();
      const middleName = String(user.middle_name || '').toLowerCase();
      const lastName = String(user.last_name || '').toLowerCase();
      const fullName = [firstName, middleName, lastName]
        .filter((name) => name)
        .join(' ');
      const searchTerms = search.split(/\s+/).filter((term) => term);
      return (
        searchTerms.every((term) => fullName.includes(term)) ||
        (user.email || '').toLowerCase().includes(search)
      );
    });

    filtered = filtered.filter((user) => {
      if (!account) return true;
      switch (account) {
        case '1':
          return user.acc_status === 'Pending';
        case '2':
          return user.acc_status === 'Active';
        case '3':
          return user.acc_status === 'Warn';
        case '4':
          return user.acc_status === 'Suspend';
        case '5':
          return user.acc_status === 'Ban';
        case '6':
          return user.acc_status === 'Block';
        case '7':
          return user.acc_status === 'Deactivate';
        case '8':
          return user.acc_status === 'Review';
        case '9':
          return user.acc_status === 'Reject';
        default:
          return true;
      }
    });

    filtered = filtered.filter((user) => {
      if (!role) return true;
      switch (role) {
        case '1':
          return user.user_role === 'Client';
        case '2':
          return user.user_role === 'Tasker';
        case '3':
          return user.user_role === 'Moderator';
        case '4':
          return user.user_role === 'Admin';
        default:
          return true;
      }
    });

    filtered = filtered.filter((user) => {
      if (!status) return true;
      switch (status) {
        case '1':
          return user.status === true;
        case '2':
          return user.status === false;
        default:
          return true;
      }
    });

    filtered.sort((a, b) => {
      if (this.activeSortColumn === 'profile' && this.profileSortState !== 'default') {
        const aFullName = `${a.first_name || ''} ${a.middle_name || ''} ${a.last_name || ''}`.toLowerCase().trim();
        const bFullName = `${b.first_name || ''} ${b.middle_name || ''} ${b.last_name || ''}`.toLowerCase().trim();
        return this.profileSortState === 'asc'
          ? aFullName.localeCompare(bFullName)
          : bFullName.localeCompare(aFullName);
      }
      if (this.activeSortColumn === 'email' && this.emailSortState !== 'default') {
        const aEmail = (a.email || '').toLowerCase().trim();
        const bEmail = (b.email || '').toLowerCase().trim();
        return this.emailSortState === 'asc'
          ? aEmail.localeCompare(bEmail)
          : bEmail.localeCompare(aEmail);
      }
      return new Date(b.created_at).getTime() - new Date(a.created_at).getTime(); // Newest to oldest
    });

    return filtered;
  }

  toggleUsers(checked: boolean): void {
    this.users = this.users.map((user) => ({
      ...user,
      selected: checked,
    }));
  }

  handleSort(event: { column: 'profile' | 'email'; state: 'default' | 'asc' | 'desc' }): void {
    if (event.column === 'profile') {
      this.profileSortState = event.state;
      this.emailSortState = 'default'; // Reset email sort
      this.activeSortColumn = event.state === 'default' ? null : 'profile';
    } else if (event.column === 'email') {
      this.emailSortState = event.state;
      this.profileSortState = 'default'; // Reset profile sort
      this.activeSortColumn = event.state === 'default' ? null : 'email';
    }
    const pageSize = this.filterService.pageSizeField();
    this.filterService.setCurrentUsers(this.filteredUsers.slice(0, pageSize));
  }

  handleRequestError(error: any): void {
    console.error('API Request Error:', error);
    toast.error(error?.message || 'An unknown error occurred');
  }

  navigateToAddUser(): void {
    this.router.navigate(['user-management/add-user']);
  }

  navigateToUpdateUser(): void {
    this.router.navigate(['user-management/update-user']);
  }
}