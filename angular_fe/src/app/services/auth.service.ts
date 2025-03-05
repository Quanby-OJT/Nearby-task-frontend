import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { catchError, Observable, throwError } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private apiUrl = `${environment.apiUrl}`;
  constructor(private router: Router, private http: HttpClient, private session: SessionLocalStorage) {}

  userInformation(): Observable<any> {
    const user_id = localStorage.getItem('user_id');
    return this.http.post<any>(`${this.apiUrl}/userInformation`, { user_id }).pipe(
      catchError((error) => {
        console.error('HTTP Error:', error);
        return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
      }),
    );
  }

  login(email: string, password: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/login`, { email, password }).pipe(
      catchError((error) => {
        console.error('HTTP Error:', error);
        return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
      }),
    );
  }

  logout(userID: Number): Observable<any> {
    const sessionData = this.session.getSession();
    const sessionID = typeof sessionData === 'string' ? sessionData.trim() : JSON.stringify(sessionData).trim();

    // Clean both values
    const cleanedSessionID = sessionID.replace(/^"|"$/g, '').trim();
    // console.log('logout: ' + sessionData);
    return this.http.post<any>(`${this.apiUrl}/logout`, { userID, cleanedSessionID }).pipe(
      catchError((error) => {
        console.error('HTTP Error:', error);
        return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
      }),
    );
  }

  logoutWithoutSession(sessionID: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/logout-without-session`, { sessionID }).pipe(
      catchError((error) => {
        console.error('HTTP Error:', error);
        return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
      }),
    );
  }
}
