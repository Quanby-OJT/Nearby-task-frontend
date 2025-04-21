import { NgClass, NgIf } from '@angular/common';
import { Component, Injectable, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink, CanActivateFn } from '@angular/router';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { ButtonComponent } from '../../../../shared/components/button/button.component';
import { AuthService } from 'src/app/services/auth.service';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({ providedIn: 'root' })
@Component({
  selector: 'app-sign-in',
  templateUrl: './sign-in.component.html',
  styleUrls: ['./sign-in.component.css'],
  imports: [FormsModule, ReactiveFormsModule, RouterLink, AngularSvgIconModule, NgIf, ButtonComponent, NgClass],
})
export class SignInComponent implements OnInit {
  form!: FormGroup;
  submitted = false;
  passwordTextType!: boolean;
  errorMessage: string | null = null;

  constructor(
    private readonly _formBuilder: FormBuilder,
    private readonly _router: Router,
    private authService: AuthService,
    private sessionStorage: SessionLocalStorage,
  ) {}

  onClick() {
    console.log('Button clicked');
  }

  ngOnInit(): void {
    this.form = this._formBuilder.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required],
    });
  }

  get f() {
    return this.form.controls;
  }

  togglePasswordTextType() {
    this.passwordTextType = !this.passwordTextType;
  }

  onSubmit() {
    this.submitted = true;

    const { email, password } = this.form.value;
    console.log('Email:', email, 'password:', password);
    if (this.form.invalid) {
      return;
    }
    this.login(email, password);
  }

  login(email: string, password: string) {
    this.authService.login(email, password).subscribe({
      next: (response) => {
        console.log('Login successful', response.userSession);
        this.sessionStorage.setSessionLocal(response.userSession);
        const sessionData = this.sessionStorage.session() as Record<string, any>;
        const session = Object.keys(sessionData)[0];
        console.log('Session:', session);
        const userId = sessionData[session]?.user;
        this.sessionStorage.setSession(session);
        this.sessionStorage.setSessionToken(response.sessionID);
        this.sessionStorage.setUserId(userId);
        this._router.navigate(['/dashboard']);
      },
      error: (error) => {
        console.log('Login error', error);
        this.errorMessage = error;
        this.form.reset();
      },
    });
  }

  logout(userID: Number) {
    console.log('Logout successful', userID);
    this.authService.logout(userID).subscribe({
      next: (response) => {
        console.log('Log successful', response);
        sessionStorage.removeItem('session');
        localStorage.removeItem('user_id');
        localStorage.removeItem('session');
        localStorage.removeItem('sessionToken');
        this._router.navigate(['/auth/sign-in']);
      },
      error: (error) => {
        console.log('Login error', error);
      },
    });
  }
}