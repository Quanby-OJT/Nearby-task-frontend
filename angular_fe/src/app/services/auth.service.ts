import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { catchError, Observable, throwError } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(private router: Router, private http: HttpClient, private session: SessionLocalStorage) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.session.getSessionToken()}`
    });
  }
  
  userInformation(): Observable<any> {
    const user_id = localStorage.getItem('user_id');
    return this.http.post<any>(
      `${this.apiUrl}/userInformation`,
      { user_id },
      {
        headers: this.getHeaders(),
        withCredentials: true
      }
    ).pipe(
      catchError((error) => {
        console.error('HTTP Error:', error);
        return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
      }),
    );
  }

  login(email: string, password: string): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/login-angular`,
      { email, password },
      { withCredentials: true }
    ).pipe(
      catchError((error: HttpErrorResponse) => {
        let apiError: any;
        if (error.status === 0) {
          apiError = new Error('Your internet connection is low. Please check your connection or try again later.');
          apiError.type = 'network';
        } else if (error.error && error.error.message) {
          apiError = new Error(error.error.message);
          apiError.type = 'authentication';
        } else {
          apiError = new Error('Unknown error occurred. Please contact the authority to fix this problem.');
          apiError.type = 'unknown';
        }
        return throwError(() => apiError);
      }),
    );
  }

  logout(userID: Number): Observable<any> {
    const sessionData = this.session.getSessionToken();
    const sessionID = typeof sessionData === 'string' ? sessionData.trim() : JSON.stringify(sessionData).trim();

    // Clean both values
    const cleanedSessionID = sessionID.replace(/^"|"$/g, '').trim();
    console.log('logout: ' + sessionData);
    return this.http.post<any>(
      `${this.apiUrl}/logout-angular`,
      { userID, cleanedSessionID },
      {
        headers: this.getHeaders(),
        withCredentials: true
      }
    ).pipe(
      catchError((error) => {
        console.error('HTTP Error:', error);
        return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
      }),
    );
  }

  logoutWithoutSession(sessionID: string): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/logout-without-session`,
      { sessionID },
      {
        headers: this.getHeaders(),
        withCredentials: true
      }
    ).pipe(
      catchError((error) => {
        console.error('HTTP Error:', error);
        return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
      }),
    );
  }
}