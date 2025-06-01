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
import { AuthService } from 'src/app/services/auth.service';

@Component({
  selector: '[app-table-row]',
  imports: [FormsModule, AngularSvgIconModule, NgClass, CommonModule],
  templateUrl: './table-row.component.html',
  styleUrls: ['./table-row.component.css'],
})
export class UserTableRowComponent {
  @Input() user: Users = <Users>{};
  actionByName: string = '';
  userRole: string | undefined;
  constructor(
    private route: Router,
    private UserAccountService: UserAccountService,
    private UserComponent: UsersComponent,
    private dataService: DataService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.loadActionByName();
    this.authService.userInformation().subscribe(
      (response: any) => {
        this.userRole = response.user.user_role;
      },
      (error: any) => {
        console.error('Error fetching user role:', error);
      }
    );
  }

  loadActionByName(): void {
    console.log('Current user data:', this.user);
    if (this.user.action_by) {
      console.log('Fetching user with action_by:', this.user.action_by);
      this.UserAccountService.getUserById(Number(this.user.action_by)).subscribe({
        next: (response: any) => {
          console.log('Received response:', response);
          
          // Get the latest action taken by record
          const actionTakenBy = response.action_taken_by;
          if (actionTakenBy && actionTakenBy.length > 0) {
            // Sort by created_at to get the most recent action
            const latestAction = actionTakenBy.sort((a: any, b: any) => 
              new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
            )[0];
            
            if (latestAction && latestAction.user) {
              const actionUser = latestAction.user;
              this.actionByName = `${actionUser.first_name || ''} ${actionUser.middle_name || ''} ${actionUser.last_name || ''}`.trim();
              console.log('Set actionByName to:', this.actionByName);
            } else {
              console.warn('No user data found in action_taken_by');
              this.actionByName = 'No Action Yet';
            }
          } else {
            console.warn('No action_taken_by records found');
            this.actionByName = 'No Action Yet';
          }
        },
        error: (error: any) => {
          console.error('Error fetching action_by user data:', error);
          this.actionByName = 'No Action Yet';
        },
      });
    } else {
      console.log('No action_by found for user');
      this.actionByName = 'No Action Yet';
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