import { NgClass, NgIf } from '@angular/common';
import { Component, numberAttribute } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterOutlet } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';
import { ButtonComponent } from 'src/app/shared/components/button/button.component';
import { DataService } from 'src/services/dataStorage';
import Swal from 'sweetalert2';
import { ChangeDetectorRef } from '@angular/core';

@Component({
  selector: 'app-update-user',
  imports: [RouterOutlet, ReactiveFormsModule, NgIf, ButtonComponent, NgClass],
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
 // Add property for current date

  constructor(
    private _formBuilder: FormBuilder,
    private userAccountService: UserAccountService,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: DataService,
    private cdRef: ChangeDetectorRef
  ) {[]
    const now= new Date();
    this.today = now.toISOString().split('T')[0];
  }

  ngOnInit(): void {
    this.formValidation();
    this.userId = this.dataService.getUserID();
    if (!this.userId || this.userId === 0) {
      this.router.navigate(['user-management']);
    } else {
      this.loadUserData();
      console.log('User ID:', this.userId);
    }
  }

  formValidation(): void {
    this.form = this._formBuilder.group({
      firstName: ['', Validators.required],
      middleName: [''],
      lastName: ['', Validators.required],
      status: ['', Validators.required],
      userRole: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      bday: ['', Validators.required],
    });
  }

  loadUserData(): void {
    this.isLoading = true;
    const userId = Number(this.userId);
    console.log('Loading data for user ID:', userId);

    this.userAccountService.getUserById(userId).subscribe({
      next: (response: any) => {
        console.log('Raw Backend Response:', response);
        
        // Handle different response structures
        if (response.userme) {
          // Tasker response
          this.userData = response.user;
        } else if (response.client) {
          // Client response
          this.userData = response.user;
        } else if (response.user) {
          // Admin/Moderator/Other response
          this.userData = response.user;
        } else {
          // Fallback if none of the above
          this.userData = response;
        }
        
        console.log('Processed User Data:', this.userData);

        if (this.userData) {
          // Map the data from Supabase columns to form fields
          this.form.patchValue({
            firstName: this.userData.first_name || '',
            middleName: this.userData.middle_name || '',
            lastName: this.userData.last_name || '',
            bday: this.userData.birthdate
              ? new Date(this.userData.birthdate).toISOString().split('T')[0]
              : '',
            userRole: this.userData.user_role || '', 
            email: this.userData.email || '',
            status: this.userData.acc_status || this.userData.status || '',
          });

          // Handle profile image
          this.profileImage = this.userData.image_link || null;
          console.log('Form Value After Patch:', this.form.value);
          console.log('Profile Image:', this.profileImage);
          
          // Force change detection
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

  onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      Swal.fire({
        icon: 'error',
        title: 'Validation Error',
        text: 'Please check the form for errors!',
      });
      return;
    }

    const userId = Number(this.userId);
    this.updateUserAccount(userId);
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