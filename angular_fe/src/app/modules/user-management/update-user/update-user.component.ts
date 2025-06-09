import { NgClass, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';
import { ButtonComponent } from 'src/app/shared/components/button/button.component';
import { DataService } from 'src/services/dataStorage';
import Swal from 'sweetalert2';
import { ChangeDetectorRef } from '@angular/core';

@Component({
  selector: 'app-update-user',
  imports: [ReactiveFormsModule, NgIf, ButtonComponent, NgClass],
  templateUrl: './update-user.component.html',
  styleUrl: './update-user.component.css',
})
export class UpdateUserComponent {
  form!: FormGroup;
  submitted = false;
  imagePreview: File | null = null;
  duplicateEmailError: any = null;
  success_message: any = null;
  userId: Number | null = null;
  imageUrl: string | null = null;
  userData: any = null;
  first_name: string = '';
  profileImage: string | null = null;
  isLoading: boolean = true;
  today: string;
  actionByName: string = '';
  userRole: string = '';

  constructor(
    private _formBuilder: FormBuilder,
    private userAccountService: UserAccountService,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: DataService,
    private cdRef: ChangeDetectorRef
  ) {
    const now = new Date();
    this.today = now.toISOString().split('T')[0];
  }

  ngOnInit(): void {
    this.formValidation();
    this.userId = this.dataService.getUserID();
    if (!this.userId || this.userId === 0) {
      this.router.navigate(['user-management']);
    } else {
      this.loadUserData();
      this.loadActionByName();
      console.log('User ID:', this.userId);
    }

    // Get current user's role
    const currentUserId = localStorage.getItem('user_id');
    if (currentUserId) {
      this.userAccountService.getUserById(Number(currentUserId)).subscribe({
        next: (response: any) => {
          const user = response.user || response;
          this.userRole = user.user_role || 'Unknown';
          this.cdRef.detectChanges();
        },
        error: (error: any) => {
          console.error('Error fetching current user role:', error);
          this.userRole = 'Unknown';
          this.cdRef.detectChanges();
        }
      });
    }
  }

  calculateAge(birthdate: string): number {
    if (!birthdate) return 0;
    const today = new Date();
    const birthDate = new Date(birthdate);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  }

  formValidation(): void {
    this.form = this._formBuilder.group({
      firstName: [''],
      middleName: [''],
      lastName: [''],
      status: [''],
      userRole: [''],
      email: [''],
      bday: [''],
      age: [{ value: '', disabled: true }]
    });
  }

  loadUserData(): void {
    this.isLoading = true;
    const userId = Number(this.userId);
    console.log('Loading data for user ID:', userId);

    this.userAccountService.getUserById(userId).subscribe({
      next: (response: any) => {
        console.log('Raw Backend Response:', response);
        
        // Debugging: Log the keys available in the response object
        console.log('Response keys:', Object.keys(response));

        if (response.userme) {
          this.userData = response.user;
          console.log('Identified user data under response.user (userme)');
        } else if (response.client) {
          this.userData = response.user; // Assuming client response also has user nested
          console.log('Identified user data under response.user (client)');
        } else if (response.user) {
          this.userData = response.user;
          console.log('Identified user data under response.user');
        } else {
          // Fallback if nesting is different
          this.userData = response;
          console.log('Identified user data at top level of response');
        }
        
        console.log('Processed User Data:', this.userData);

        if (this.userData) {
          // If there's an action_by, fetch that user's data to get their role
          if (this.userData.action_by) {
            this.userAccountService.getUserById(Number(this.userData.action_by)).subscribe({
              next: (actionByResponse: any) => {
                const actionByUser = actionByResponse.user || actionByResponse;
                this.userData.action_by_user = {
                  first_name: actionByUser.first_name,
                  middle_name: actionByUser.middle_name,
                  last_name: actionByUser.last_name,
                  user_role: actionByUser.user_role
                };
                this.cdRef.detectChanges();
              },
              error: (error: any) => {
                console.error('Error fetching action_by user data:', error);
              }
            });
          }

          const birthdate = this.userData.birthdate
            ? new Date(this.userData.birthdate).toISOString().split('T')[0]
            : '';
          const age = this.calculateAge(birthdate);

          this.form.patchValue({
            firstName: this.userData.first_name || '',
            middleName: this.userData.middle_name || '',
            lastName: this.userData.last_name || '',
            bday: birthdate,
            age: age,
            userRole: this.userData.user_role || '',
            email: this.userData.email || '',
            status: this.userData.acc_status || this.userData.status || '',
          });

          console.log('Form Value After Patch:', this.form.value);
          this.profileImage = this.userData.image_link || null;
          console.log('Profile Image:', this.profileImage);
          
          this.cdRef.detectChanges();
        } else {
          console.warn('No user data found in response');
          Swal.fire({
            icon: 'warning',
            title: 'No Data',
            text: 'User data not found for this ID.',
          });
        }
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error fetching user data:', error);
        this.isLoading = false;
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Failed to load user data: ' + (error.message || 'Unknown error'),
        });
      },
    });
  }

  loadActionByName(): void {
    const actionById = localStorage.getItem('user_id');
    if (actionById) {
      this.userAccountService.getUserById(Number(actionById)).subscribe({
        next: (response: any) => {
          const user = response.user || response;
          this.actionByName = `${user.first_name || ''} ${user.middle_name || ''} ${user.last_name || ''}`.trim();
          this.cdRef.detectChanges();
        },
        error: (error: any) => {
          console.error('Error fetching action_by user data:', error);
          this.actionByName = 'Unknown User';
          this.cdRef.detectChanges();
        },
      });
    }
  }

  onFileChange(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const file = input.files[0];
      this.imagePreview = file;
      const reader = new FileReader();
      reader.onload = () => {
        this.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  get f() {
    return this.form.controls;
  }

  async onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      Swal.fire({
        icon: 'error',
        title: 'Validation Error',
        text: 'Please check the form for errors!',
      });
      return;
    }

    // Check if current user is Moderator and prior action was by Admin
    if (this.userRole === 'Moderator' && this.userData?.action_by_user?.user_role === 'Admin') {
      await Swal.fire('Error', "You don't have authority to take action here since this action is made by an admin", 'error');
      return;
    }

    const userId = Number(this.userId);

    // Show SweetAlert2 modal to capture reason
    const { value: reason } = await Swal.fire({
      title: 'Update User Status',
      html: `
        <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for this action</label>
        <input id="reason-input" class="swal2-input" placeholder="Enter reason" />
      `,
      showCancelButton: true,
      confirmButtonText: 'Confirm',
      cancelButtonText: 'Cancel',
      preConfirm: () => {
        const reasonInput = (document.getElementById('reason-input') as HTMLInputElement).value;
        if (!reasonInput) {
          Swal.showValidationMessage('Please provide a reason for this action');
        }
        return reasonInput;
      },
      willOpen: () => {
        const confirmButton = Swal.getConfirmButton();
        const reasonInput = document.getElementById('reason-input') as HTMLInputElement;
        if (confirmButton) {
          confirmButton.disabled = true;
        }
        reasonInput.addEventListener('input', () => {
          if (confirmButton) {
            confirmButton.disabled = !reasonInput.value.trim();
          }
        });
      }
    });

    if (reason) {
      // Prepare user data for the update
      const userData = {
        first_name: this.form.value.firstName,
        middle_name: this.form.value.middleName,
        last_name: this.form.value.lastName,
        birthday: this.form.value.bday,
        email: this.form.value.email,
        acc_status: this.form.value.status,
        user_role: this.form.value.userRole,
      };

      // Call the service method with reason
      this.userAccountService.updateUserAccountWithReason(userId, userData, reason).subscribe(
        (response) => {
          Swal.fire({
            icon: 'success',
            title: 'Success',
            text: 'User status updated successfully!',
          }).then(() => {
            this.router.navigate(['user-management']);
          });
        },
        (error) => {
          Swal.fire({
            icon: 'error',
            title: 'Update Failed',
            text: error.error?.error || 'An error occurred while updating the user status.',
          });
        }
      );
    }
  }

  updateUserAccount(userId: number): void {
    const formData = new FormData();
    formData.append('first_name', this.form.value.firstName);
    formData.append('middle_name', this.form.value.middleName);
    formData.append('last_name', this.form.value.lastName);
    formData.append('birthday', this.form.value.bday);
    formData.append('email', this.form.value.email);
    formData.append('acc_status', this.form.value.status);
    formData.append('user_role', this.form.value.userRole);
    formData.append('action_by', localStorage.getItem('user_id') || '0');

    if (this.imagePreview) {
      formData.append('image', this.imagePreview, this.imagePreview.name);
    }

    this.userAccountService.updateUserAccount(userId, formData).subscribe(
      (response) => {
        Swal.fire({
          icon: 'success',
          title: 'Success',
          text: 'User updated successfully!',
        }).then(() => {
          this.router.navigate(['user-management']);
        });
      },
      (error) => {
        Swal.fire({
          icon: 'error',
          title: 'Update Failed',
          text: error.error?.error || 'An error occurred while updating the user.',
        });
      }
    );
  }

  navigateToUsermanagement(): void {
    this.router.navigate(['user-management']);
  }
}