import { HttpClient } from '@angular/common/http';
import { Component, effect, ElementRef, OnInit, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { toast } from 'ngx-sonner';
import { UserTableActionComponent } from '../table/table-action/table-action.component';
import { UserTableFooterComponent } from '../table/table-footer/table-footer.component';
import { UserTableHeaderComponent } from '../table/table-header/table-header.component';
import { UserTableRowComponent } from '../table/table-row/table-row.component';
import { AddUserComponent } from '../add-user/add-user.component';
import { Router, RouterOutlet } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';
import { UserTableFilterService } from 'src/services/user-table-filter';
import { ButtonComponent } from 'src/app/shared/components/button/button.component';
import { ReviewComponent } from '../review/review.component';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { NgIf } from '@angular/common';

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
    AddUserComponent,
    RouterOutlet,
    ButtonComponent,
    ReviewComponent,
    NgIf,
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

  constructor(
    private http: HttpClient,
    private filterService: UserTableFilterService,
    private router: Router,
    private useraccount: UserAccountService,
  ) {
    effect(() => {
      const currentPage = this.filterService.currentPageField();
      const pageSize = this.filterService.pageSizeField();
      this.loadUsers(currentPage, pageSize);
    });
  }

  loadUsers(page: number, pageSize: number) {
    this.useraccount.getUsers(page, pageSize).subscribe(
      (response) => {
        console.log('Fetched Users:', response.users);
        this.filterService.setCurrentUsers(response.users || []);
        this.filterService.userSizeField.set(response.total || 0);
      },
      (error) => {
        console.error('Load Users Error:', error);
      },
    );
  }

  ngOnInit(): void {
    this.fetchUsers();
    this.setUserSize();
  }

  exportPDF() {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });

    const title = 'Users Report';

    const img = new Image();
    img.src = 'assets/image/sample.png'; // Replace with your image source
    doc.addImage(img, 'png', 10, 10, 50, 50); // x, y, width, height
    doc.line(10, 70, 200, 70); // x1, y1, x2, y2
    img.onload = () => {
      doc.addImage(img, 'PNG', 30, 20, 100, 100);
    };

    // Add Title
    doc.setFontSize(20);
    doc.text(title, 170, 45); //w and h

    // Define Table Columns & Rows
    const columns = ['Fullname', 'Role', 'Email', 'Account', 'Status'];
    const rows = this.filteredUsers.map((item) => [
      item.first_name + ' ' + (item.middle_name === null ? '' : item.middle_name) + ' ' + item.last_name,
      item.user_role,
      item.email,
      item.acc_status,
      item.status,
    ]);

    // Generate Table
    autoTable(doc, {
      startY: 100, // Start table below the title
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });

    // Save PDF
    doc.save('User_table.pdf');
  }

  setUserSize(): void {
    this.useraccount.getUsers(1, 10).subscribe((users) => {
      this.filterService.setUsers(this.users);
    });
  }

  get UserSize(): number {
    return this.users.length;
  }

  fetchUsers(): void {
    this.useraccount.getAllUsers().subscribe(
      (response: any) => {
        this.users = response.users;
        this.filterService.setUsers(this.users);
      },
      (error: any) => {
        console.error('Error fetching users:', error);
        this.handleRequestError(error);
      },
    );
  }

  get filteredUsers(): any[] {
    const search = this.filterService.searchField().toLowerCase() || '';
    const account = this.filterService.statusField();
    const status = this.filterService.onlineField();
    const role = this.filterService.roleField();
    this.PaginationUsers = this.filterService.currentUsers();

    // Apply search filter on full name
    let filtered = this.PaginationUsers.filter((user) => {
      // Create full name by concatenating first_name, middle_name, and last_name
      const firstName = String(user.first_name || '').toLowerCase();
      const middleName = String(user.middle_name || '').toLowerCase();
      const lastName = String(user.last_name || '').toLowerCase();
      const fullName = [firstName, middleName, lastName]
        .filter((name) => name) // Remove empty strings
        .join(' ');

      // Split search terms to allow matching individual words
      const searchTerms = search.split(/\s+/).filter((term) => term);

      // Check if all search terms are present in the full name or email
      return (
        searchTerms.every((term) => fullName.includes(term)) ||
        (user.email || '').toLowerCase().includes(search)
      );
    });

    // Apply account status filter
    filtered = filtered.filter((user) => {
      if (!account) return true;
      switch (account) {
        case '1':
          return user.acc_status === 'verified';
        case '2':
          return user.acc_status === 'review';
        case '3':
          return user.acc_status === 'rejected';
        case '4':
          return user.acc_status === 'blocked';
        default:
          return true;
      }
    });

    // Apply role filter
    filtered = filtered.filter((user) => {
      if (!role) return true;
      switch (role) {
        case '1':
          return user.user_role === 'client';
        case '2':
          return user.user_role === 'tasker';
        case '3':
          return user.user_role === 'moderator';
        default:
          return true;
      }
    });

    // Apply online status filter
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

    return filtered;
  }

  toggleUsers(checked: boolean): void {
    this.users = this.users.map((user) => ({
      ...user,
      selected: checked,
    }));
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