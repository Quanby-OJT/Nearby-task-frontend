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

  constructor(private userAccountService: UserAccountService, private router: Router) {}

  ngOnInit(): void {}

  async nextStep(form: NgForm) {
    if (this.currentStep === 1) {
      if (!form.valid) {
        alert('Please enter a valid email address.');
        return;
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
        alert('Please enter a valid 6-digit OTP.');
        return;
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
      if (!this.newPassword || !this.confirmPassword) {
        alert('Please fill in both password fields.');
        return;
      }
      if (this.newPassword !== this.confirmPassword) {
        alert('Passwords do not match.');
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