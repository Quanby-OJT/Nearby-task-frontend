import { Component, OnInit } from '@angular/core';
// import { ActivatedRoute } from '@angular/router'; // Removed ActivatedRoute
import { CommonModule } from '@angular/common';
import { AuthService } from 'src/app/services/auth.service'; // Import AuthService
import { UserAccountService } from 'src/app/services/userAccount'; // Import UserAccountService
import { Users } from 'src/model/user-management'; // Import Users model
import { toast } from 'ngx-sonner'; // Import toast for error handling
import {
  ReactiveFormsModule, // Import ReactiveFormsModule
  FormGroup,
  FormControl,
  Validators,
  FormBuilder // Import FormBuilder
} from '@angular/forms';

@Component({
  selector: 'app-my-profile',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule // Add ReactiveFormsModule here
  ],
  templateUrl: './my-profile.component.html',
  styleUrl: './my-profile.component.css'
})
export class MyProfileComponent implements OnInit { // Implement OnInit
  user: Users | null = null; // Property to hold user data
  isLoading: boolean = true;
  isSaving: boolean = false; // Add saving state
  profileForm!: FormGroup; // Initialize profileForm
  submitted = false; // Track form submission
  imageUrl: string | null = null; // For image preview

  constructor(
    private authService: AuthService,
    private userAccountService: UserAccountService, // Inject UserAccountService
    private fb: FormBuilder // Inject FormBuilder
  ) {} // Inject AuthService

  ngOnInit() {
    this.isLoading = true;
    this.authService.userInformation().subscribe(
      (response: any) => {
        console.log('User Information for Profile:', response.user);
        this.user = response.user;
        this.initializeForm(); // Initialize form after getting user data
        this.imageUrl = this.user?.image_link || null;
        this.isLoading = false;
      },
      (error: any) => {
        console.error('Error fetching user for profile:', error);
        toast.error('Failed to load profile information.');
        this.isLoading = false;
      }
    );
  }

  initializeForm() {
    if (!this.user) return;
    this.profileForm = this.fb.group({
      first_name: [this.user.first_name, Validators.required],
      middle_name: [this.user.middle_name],
      last_name: [this.user.last_name, Validators.required],
      email: [{ value: this.user.email, disabled: true }], // Keep email non-editable for now
      contact: [this.user.contact],
      gender: [this.user.gender],
      birthdate: [this.user.birthdate ? new Date(this.user.birthdate).toISOString().split('T')[0] : null], // Format for date input
      profileImage: [null] // For file input
    });
  }

  // Getter for easy access to form controls in the template
  get f() { return this.profileForm.controls; }

  onFileChange(event: Event) {
    const element = event.currentTarget as HTMLInputElement;
    let fileList: FileList | null = element.files;
    if (fileList && fileList.length > 0) {
      const file = fileList[0];
      this.profileForm.patchValue({ profileImage: file });
      // Optional: Show preview
      const reader = new FileReader();
      reader.onload = () => {
        this.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  onSubmit() {
    this.submitted = true;

    // Stop here if form is invalid
    if (this.profileForm.invalid) {
        toast.error('Please fill all required fields correctly.');
        console.log('Form Errors:', this.profileForm.errors);
        Object.keys(this.profileForm.controls).forEach(key => {
          const controlErrors = this.profileForm.get(key)?.errors;
          if (controlErrors != null) {
            console.log('Key control: ' + key + ', errors: ', controlErrors);
          }
        });
        return;
    }

    if (!this.user?.user_id) {
        toast.error('User ID is missing. Cannot update profile.');
        return;
    }

    this.isSaving = true;
    const formData = new FormData();

    // Append form values (excluding email if disabled)
    Object.keys(this.profileForm.value).forEach(key => {
      if (key !== 'email' && key !== 'profileImage') {
        const value = this.profileForm.value[key];
        if (value !== null && value !== undefined) { // Ensure nulls aren't sent as "null"
           formData.append(key, value);
        }
      }
    });

    // Append file if selected
    const profileImageFile = this.profileForm.get('profileImage')?.value;
    if (profileImageFile instanceof File) {
      formData.append('profileImage', profileImageFile, profileImageFile.name);
    }
    
    console.log('Submitting Form Data via UserAccountService:', formData);

    // Use UserAccountService to update
    this.userAccountService.updateAuthorityUser(this.user.user_id, formData).subscribe({
      next: (response) => {
        toast.success('Profile updated successfully!');
        // Assuming the backend returns the updated user object
        this.user = response.user ? { ...(this.user as Users), ...response.user } : this.user; 
        this.imageUrl = this.user?.image_link || null;
        // Optionally re-initialize form if needed, or just update local user
        // this.initializeForm(); 
        this.isSaving = false;
        this.submitted = false;
      },
      error: (error) => {
        console.error('Error updating profile:', error);
        toast.error(error?.error?.message || 'Failed to update profile.');
        this.isSaving = false;
      }
    });
  }

}
