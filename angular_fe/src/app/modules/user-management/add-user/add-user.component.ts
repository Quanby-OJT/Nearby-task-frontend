import { UserAccountService } from './../../../services/userAccount';
import { NgClass, NgIf } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { Router, RouterOutlet } from '@angular/router';
import { ButtonComponent } from 'src/app/shared/components/button/button.component';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-add-user',
  imports: [RouterOutlet, ReactiveFormsModule, NgIf, ButtonComponent, NgClass],
  templateUrl: './add-user.component.html',
  styleUrl: './add-user.component.css',
})
export class AddUserComponent {
  form!: FormGroup;
  submitted = false;
  imagePreview: string | null = null;
  selectedFile: File | null = null; // Store the selected file for submission
  duplicateEmailError: any = null;
  success_message: any = null;
  today: string; // Add property for current date
  actionByName: string = '';
  passwordTextType: boolean = false; // Track password visibility
  confirmPasswordTextType: boolean = false; // Track confirm password visibility
  // Object to track password validation requirements
  passwordValidation = {
    minLength: false,
    lowercase: false,
    uppercase: false,
    number: false,
    specialChar: false,
    noSpaces: false,
  };

  constructor(
    private _formBuilder: FormBuilder,
    private UserAccountService: UserAccountService,
    private router: Router,
    private cdRef: ChangeDetectorRef
  ) {
    // Initialize today with current date in YYYY-MM-DD format
    const now = new Date();
    this.today = now.toISOString().split('T')[0];
  }

  ngOnInit(): void {
    this.formValidation();
    this.loadActionByName();
  }

  loadActionByName(): void {
    const actionById = localStorage.getItem('user_id');
    if (actionById) {
      this.UserAccountService.getUserById(Number(actionById)).subscribe({
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

  formValidation(): void {
    this.form = this._formBuilder.group({
      firstName: ['', Validators.required],
      middleName: [''],
      lastName: ['', Validators.required],
      status: ['', Validators.required],
      userRole: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      bday: ['', Validators.required],
      profileImage: [null, Validators.required],
      contact: ['', Validators.required],
      gender: ['', Validators.required],
      password: ['', [Validators.required, this.passwordValidator()]],
      confirmPassword: ['', [Validators.required, this.passwordValidator()]]
    }, {
      validators: this.mustMatch('password', 'confirmPassword')
    });

    // Subscribe to password value changes for real-time validation
    this.form.get('password')?.valueChanges.subscribe((value) => {
      this.validatePassword(value);
    });
  }

  // Custom validator for password requirements
  passwordValidator() {
    return (control: AbstractControl): ValidationErrors | null => {
      const value = control.value || '';
      const errors: ValidationErrors = {};

      if (!value) {
        return { required: true }; // Required validation handled separately
      }

      if (value.length < 8) {
        errors['minlength'] = true;
      }
      if (!/[a-z]/.test(value)) {
        errors['lowercase'] = true;
      }
      if (!/[A-Z]/.test(value)) {
        errors['uppercase'] = true;
      }
      if (!/\d/.test(value)) {
        errors['number'] = true;
      }
      if (!/[!@#$%^&*()]/.test(value)) {
        errors['specialChar'] = true;
      }
      if (/\s/.test(value)) {
        errors['noSpaces'] = true;
      }

      return Object.keys(errors).length > 0 ? errors : null;
    };
  }

  // Validate password requirements as the user types
  validatePassword(value: string) {
    this.passwordValidation.minLength = value.length >= 8;
    this.passwordValidation.lowercase = /[a-z]/.test(value);
    this.passwordValidation.uppercase = /[A-Z]/.test(value);
    this.passwordValidation.number = /\d/.test(value);
    this.passwordValidation.specialChar = /[!@#$%^&*()]/.test(value);
    this.passwordValidation.noSpaces = !/\s/.test(value);
  }

  // Custom validator to check if password and confirmPassword match
  mustMatch(password: string, confirmPassword: string) {
    return (formGroup: AbstractControl): ValidationErrors | null => {
      const passwordControl = formGroup.get(password);
      const confirmPasswordControl = formGroup.get(confirmPassword);

      if (!passwordControl || !confirmPasswordControl) {
        return null;
      }

      if (confirmPasswordControl.errors && !confirmPasswordControl.errors['mustMatch']) {
        return null;
      }

      if (passwordControl.value !== confirmPasswordControl.value) {
        confirmPasswordControl.setErrors({ mustMatch: true });
        return { mustMatch: true };
      } else {
        confirmPasswordControl.setErrors(null);
        return null;
      }
    };
  }

  togglePasswordTextType() {
    this.passwordTextType = !this.passwordTextType;
  }

  toggleConfirmPasswordTextType() {
    this.confirmPasswordTextType = !this.confirmPasswordTextType;
  }

  onFileChange(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const file = input.files[0];
      console.log('Selected file:', file); // Debug: Log the selected file
      console.log('File size (bytes):', file.size); // Debug: Log file size

      // Validate file type
      if (!file.type.startsWith('image/')) {
        console.error('Invalid file type:', file.type);
        Swal.fire({
          icon: 'error',
          title: 'Invalid File',
          text: 'Please upload a valid image file (e.g., JPEG, PNG).',
        });
        this.imagePreview = null;
        this.selectedFile = null;
        this.form.get('profileImage')?.setValue(null);
        return;
      }

      // Validate file size (limit to 5MB)
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSizeInBytes) {
        console.error('File too large:', file.size);
        Swal.fire({
          icon: 'error',
          title: 'File Too Large',
          text: 'Please upload an image smaller than 5MB.',
        });
        this.imagePreview = null;
        this.selectedFile = null;
        this.form.get('profileImage')?.setValue(null);
        return;
      }

      // Store the file for submission
      this.selectedFile = file;

      // Update the form control with the file
      this.form.get('profileImage')?.setValue(file);

      // Create a temporary URL for the image preview
      this.imagePreview = URL.createObjectURL(file);
      console.log('Image Preview set to:', this.imagePreview); // Debug: Log the preview URL
    } else {
      console.log('No file selected'); // Debug: Log if no file is selected
      this.imagePreview = null;
      this.selectedFile = null;
      this.form.get('profileImage')?.setValue(null);
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

    console.log('Form Submitted Successfully!');
    console.log('Form Values:', this.form.value);

    const formData = new FormData();

    formData.append('first_name', this.form.value.firstName);
    formData.append('middle_name', this.form.value.middleName);
    formData.append('last_name', this.form.value.lastName);
    formData.append('birthday', this.form.value.bday);
    formData.append('email', this.form.value.email);
    formData.append('acc_status', this.form.value.status);
    formData.append('user_role', this.form.value.userRole);
    formData.append('contact', this.form.value.contact);
    formData.append('gender', this.form.value.gender);
    formData.append('password', this.form.value.password);
    formData.append('added_by', localStorage.getItem('user_id') || '0');

    if (this.selectedFile) {
      formData.append('image', this.selectedFile); // Use the selected file
    }

    this.UserAccountService.insertAuthorityUser(formData).subscribe(
      (response) => {
        Swal.fire({
          icon: 'success',
          title: 'Success',
          text: 'User added successfully! This user can now login',
        }).then(() => {
          this.form.reset();
          this.submitted = false;
          this.imagePreview = null;
          this.selectedFile = null;
          this.passwordValidation = {
            minLength: false,
            lowercase: false,
            uppercase: false,
            number: false,
            specialChar: false,
            noSpaces: false,
          };
          this.router.navigate(['user-management']);
        });
      },
      (error: any) => {
        this.duplicateEmailError = 'Email already exists';
        Swal.fire({
          icon: 'error',
          title: 'Registration Failed',
          text: 'Email already exists. Please use a different email.',
        });
      },
    );
  }

  navigateToUsermanagement(): void {
    this.router.navigate(['user-management']);
  }
}