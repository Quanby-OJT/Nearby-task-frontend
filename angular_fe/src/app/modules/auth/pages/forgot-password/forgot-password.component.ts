import { CommonModule, NgClass } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule, NgForm } from '@angular/forms';
import { RouterLink, Router } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';

@Component({
  selector: 'app-forgot-password',
  templateUrl: './forgot-password.component.html',
  styleUrls: ['./forgot-password.component.css'],
  imports: [FormsModule, RouterLink, NgClass, CommonModule],
  standalone: true,
})
export class ForgotPasswordComponent implements OnInit {
  currentStep: number = 1;
  email: string = '';
  otp: string = '';
  newPassword: string = '';
  confirmPassword: string = '';
  showNewPassword: boolean = false;
  showConfirmPassword: boolean = false;

  // Object to track password validation requirements
  passwordValidation = {
    minLength: false,
    lowercase: false,
    uppercase: false,
    number: false,
    specialChar: false,
    noSpaces: false,
  };

  constructor(private userAccountService: UserAccountService, private router: Router) {}

  ngOnInit(): void {}

  // Validate password requirements as the user types
  validatePassword() {
    this.passwordValidation.minLength = this.newPassword.length >= 8;
    this.passwordValidation.lowercase = /[a-z]/.test(this.newPassword);
    this.passwordValidation.uppercase = /[A-Z]/.test(this.newPassword);
    this.passwordValidation.number = /\d/.test(this.newPassword);
    this.passwordValidation.specialChar = /[!@#$%^&*()]/.test(this.newPassword);
    this.passwordValidation.noSpaces = !/\s/.test(this.newPassword);
  }

  togglePasswordVisibility(field: string) {
    if (field === 'newPassword') {
      this.showNewPassword = !this.showNewPassword;
    } else if (field === 'confirmPassword') {
      this.showConfirmPassword = !this.showConfirmPassword;
    }
  }

  async nextStep(form: NgForm) {
    if (this.currentStep === 1) {
      if (!form.valid) {
        return; // Let the template handle the error display
      }
      const trimmedEmail = this.email.trim();
      console.log(`Sending OTP request for email: "${trimmedEmail}"`);
      try {
        await this.userAccountService.sendOtp(trimmedEmail).toPromise();
        this.currentStep++;
      } catch (error: any) {
        console.error('Error sending OTP:', error);
        if (error.status === 404) {
          alert('Email not found. Please register or use a different email.');
        } else {
          alert('Failed to send OTP. Please try again later.');
        }
      }
    } else if (this.currentStep === 2) {
      if (!form.valid) {
        return; // Let the template handle the error display
      }
      const trimmedOtp = this.otp.trim();
      console.log(`Verifying OTP: "${trimmedOtp}" for email: "${this.email}"`);
      try {
        await this.userAccountService.verifyOtp(this.email, trimmedOtp).toPromise();
        this.currentStep++;
      } catch (error: any) {
        console.error('Error verifying OTP:', error);
        if (error.status === 404) {
          alert('Email not found. Please start over.');
        } else if (error.status === 400) {
          alert('Invalid or expired OTP. Please try again.');
        } else {
          alert('Failed to verify OTP. Please try again later.');
        }
      }
    }
  }

  async submit() {
    if (this.currentStep === 3) {
      // Check if fields are empty
      if (!this.newPassword || !this.confirmPassword) {
        alert('Please fill in both password fields.');
        return;
      }

      // Check if passwords match
      if (this.newPassword !== this.confirmPassword) {
        alert('Passwords do not match.');
        return;
      }

      // Validate password requirements
      const passwordRegex = /^(?!.*\s)(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()]).{8,}$/;
      if (!passwordRegex.test(this.newPassword)) {
        alert('Password must be at least 8 characters long, contain at least one lowercase letter, one uppercase letter, one number, one special character (!@#$%^&*()), and no spaces.');
        return;
      }

      try {
        await this.userAccountService.resetPassword(this.email, this.newPassword, this.confirmPassword).toPromise();
        alert('Password reset successfully. Please log in with your new password.');
        this.router.navigate(['/auth/sign-in']);
      } catch (error: any) {
        console.error('Error resetting password:', error);
        if (error.status === 404) {
          alert('Email not found. Please start over.');
        } else if (error.status === 400) {
          alert('Passwords do not match.');
        } else {
          alert('Failed to reset password. Please try again later.');
        }
      }
    }
  }

  prevStep() {
    if (this.currentStep > 1) this.currentStep--;
  }
}