import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { catchError, Observable, throwError } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class UserAccountService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(private http: HttpClient, private sessionStorage: SessionLocalStorage) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }

  insertUserAccount(userData: FormData): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/userAdd`, userData, {
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  // New method for adding authority users (Admin/Moderator)
  insertAuthorityUser(userData: FormData): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/authorityAdd`, userData, {
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  deleteUser(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/deleteUser/${id}`, {
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  getAllUsers(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/userDisplay`, {
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  getUserById(userID: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getUserData/${userID}`, {
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  checkEmailExists(email: string, userId: number): Observable<boolean> {
    return this.http.get<boolean>(`${this.apiUrl}/users/check-email?email=${email}&userId=${userId}`, {
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  updateUserAccount(userID: number, userData: FormData): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/updateUserInfo/${userID}`, userData, {
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  getUsers(page: number, pageSize: number): Observable<any> {
    return this.http
      .get<{ users: any[]; total: number }>(`${this.apiUrl}/users?page=${page}&pageSize=${pageSize}`, {
        headers: this.getHeaders(),
        withCredentials: true // This enables sending cookies with the request
      })
      .pipe(
        catchError((error) => {
          console.error('HTTP Error:', error);
          return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
        }),
      );
  }
}