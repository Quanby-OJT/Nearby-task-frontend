import { CommonModule, NgClass } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { Users } from 'src/model/user-management';
import { UserAccountService } from 'src/app/services/userAccount';
import Swal from 'sweetalert2';
import { UsersComponent } from '../../users/users.component';
import { DataService } from 'src/services/dataStorage';

@Component({
  selector: '[app-table-row]',
  imports: [FormsModule, AngularSvgIconModule, NgClass, CommonModule],
  templateUrl: './table-row.component.html',
  styleUrls: ['./table-row.component.css'],
})
export class UserTableRowComponent {
  @Input() user: Users = <Users>{};
  actionByName: string = '';

  constructor(
    private route: Router,
    private UserAccountService: UserAccountService,
    private UserComponent: UsersComponent,
    private dataService: DataService,
  ) {}

  ngOnInit(): void {
    this.loadActionByName();
  }

  loadActionByName(): void {

    if (this.user.action_by) {
      this.UserAccountService.getUserById(Number(this.user.action_by)).subscribe({
        next: (response: any) => {
          const user = response.user || response;
          this.actionByName = `${user.first_name || ''} ${user.middle_name || ''} ${user.last_name || ''}`.trim();
        },
        error: (error: any) => {
          console.error('Error fetching action_by user data:', error);
          this.actionByName = '	No Action Yet';
        },
      });
    } else {
      this.actionByName = '	No Action Yet';
    }
  }

  deleteUser(id: Number): void {
    Swal.fire({
      title: 'Are you sure?',
      text: 'This action cannot be undone!',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!',
    }).then((result) => {
      if (result.isConfirmed) {
        this.UserAccountService.deleteUser(Number(id)).subscribe(() => {
          Swal.fire('Deleted!', 'User has been deleted.', 'success').then(() => {
            this.UserComponent.ngOnInit();
          });
        });
      }
    });
  }

  updateUser(id: Number) {
    this.dataService.setUserID(id);
    this.route.navigate(['user-management/update-user']);
  }

  navigateToReviewUser(id: Number) {
    this.dataService.setUserID(id);
    this.route.navigate(['user-management/review-user']);
  }
}