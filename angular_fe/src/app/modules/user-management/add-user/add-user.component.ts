import { UserAccountService } from './../../../services/userAccount';
import { NgClass, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
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
  imagePreview: File | null = null;
  duplicateEmailError: any = null;
  success_message: any = null;

  constructor(
    private _formBuilder: FormBuilder,
    private UserAccountService: UserAccountService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.formValidation();
  }

  formValidation(): void {
    this.form = this._formBuilder.group({
      firstName: ['', Validators.required],
      middleName: [''],
      lastName: ['', Validators.required],
      status: ['', Validators.required],
      userRole: ['', Validators.required],
      email: ['', Validators.required],
      bday: ['', Validators.required],
      profileImage: ['', Validators.required],
    });
  }

  onFileChange(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.imagePreview = input.files[0];
    }
  }

  get f() {
    return this.form.controls;
  }

  onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      // console.log('Form is invalid. Please check the errors.');
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
    if (this.imagePreview) {
      formData.append('image', this.imagePreview);
    }

    this.UserAccountService.insertUserAccount(formData).subscribe(
      (response) => {
        Swal.fire({
          icon: 'success',
          title: 'Success',
          text: 'User registered successfully!',
        }).then(() => {
          this.form.reset();
          this.submitted = false;
          this.router.navigate(['user-management']);
        });
      },
      (error: any) => {
        // console.error('Error adding user:', error);
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
