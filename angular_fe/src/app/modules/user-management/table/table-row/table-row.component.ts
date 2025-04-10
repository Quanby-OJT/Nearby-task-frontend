import { CommonModule, NgClass } from '@angular/common';
import { Component, Input, OnInit } from '@angular/core';
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
  styleUrl: './table-row.component.css',
})
export class UserTableRowComponent {
  @Input() user: Users = <Users>{};
  users: any[] = [];

  constructor(
    private route: Router,
    private UserAccountService: UserAccountService,
    private UserComponent: UsersComponent,
    private dataService: DataService,
  ) {}

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