import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from 'src/app/services/auth.service';
import { UserAccountService } from 'src/app/services/userAccount';
import { Users } from 'src/model/user-management';
import { toast } from 'ngx-sonner';

import {
  ReactiveFormsModule,
  FormGroup,
  FormControl,
  Validators,
  FormBuilder
} from '@angular/forms';
import { Router } from '@angular/router';

@Component({
  selector: 'app-my-profile',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule
  ],
  templateUrl: './my-profile.component.html',
  styleUrl: './my-profile.component.css'
})
export class MyProfileComponent implements OnInit {
  user: Users | null = null;
  isLoading: boolean = true;
  isSaving: boolean = false;
  profileForm!: FormGroup;
  submitted = false;
  imageUrl: string | null = null;

  constructor(
    private authService: AuthService,
    private router: Router,
    private userAccountService: UserAccountService,
    private fb: FormBuilder
  ) {}

  ngOnInit() {
    this.isLoading = true;
    this.authService.userInformation().subscribe(
      (response: any) => {
        console.log('User Information for Profile:', response.user);
        this.user = response.user;
        this.initializeForm();
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
      email: [{ value: this.user.email, disabled: true }],
      newPassword: ['', [Validators.minLength(8)]],
      confirmPassword: [''],
      contact: [this.user.contact],
      gender: [this.user.gender],
      birthdate: [this.user.birthdate ? new Date(this.user.birthdate).toISOString().split('T')[0] : null],
      profileImage: [null]
    }, { validators: this.passwordMatchValidator });
  }

  passwordMatchValidator(form: FormGroup) {
    const newPassword = form.get('newPassword')?.value;
    const confirmPassword = form.get('confirmPassword')?.value;
    if (newPassword && confirmPassword && newPassword !== confirmPassword) {
      form.get('confirmPassword')?.setErrors({ mismatch: true });
    } else {
      form.get('confirmPassword')?.setErrors(null);
    }
    return null;
  }

  get f() { return this.profileForm.controls; }

  onFileChange(event: Event) {
    const element = event.currentTarget as HTMLInputElement;
    let fileList: FileList | null = element.files;
    if (fileList && fileList.length > 0) {
      const file = fileList[0];
      this.profileForm.patchValue({ profileImage: file });
      const reader = new FileReader();
      reader.onload = () => {
        this.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  onSubmit() {
    this.submitted = true;

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

    Object.keys(this.profileForm.value).forEach(key => {
      if (key !== 'email' && key !== 'profileImage' && key !== 'newPassword' && key !== 'confirmPassword') {
        const value = this.profileForm.value[key];
        if (value !== null && value !== undefined) {
          formData.append(key, value);
        }
      }
    });

    const profileImageFile = this.profileForm.get('profileImage')?.value;
    if (profileImageFile instanceof File) {
      formData.append('profileImage', profileImageFile, profileImageFile.name);
    }

    console.log('Submitting Form Data via UserAccountService:', formData);

    this.userAccountService.updateAuthorityUser(this.user.user_id, formData).subscribe({
      next: (response) => {
        const newPassword = this.profileForm.get('newPassword')?.value;
        if (newPassword) {
          this.userAccountService.updatePassword(this.user!.email, newPassword).subscribe({
            next: () => {
              toast.success('Profile and password updated successfully!');
              this.user = response.user ? { ...(this.user as Users), ...response.user } : this.user;
              this.imageUrl = this.user?.image_link || null;
              this.isSaving = false;
              this.submitted = false;
              this.profileForm.get('newPassword')?.reset();
              this.profileForm.get('confirmPassword')?.reset();
            },
            error: (error) => {
              console.error('Error updating password:', error);
              toast.error(error?.error?.message || 'Failed to update password.');
              this.isSaving = false;
            }
          });
        } else {
          toast.success('Profile updated successfully!');
          this.user = response.user ? { ...(this.user as Users), ...response.user } : this.user;
          this.imageUrl = this.user?.image_link || null;
          this.isSaving = false;
          this.submitted = false;
        }
      },
      error: (error) => {
        console.error('Error updating profile:', error);
        toast.error(error?.error?.message || 'Failed to update profile.');
        this.isSaving = false;
      }
    });
  }

  dashboard() {
    this.router.navigate(['/dashboard']);
  }
}