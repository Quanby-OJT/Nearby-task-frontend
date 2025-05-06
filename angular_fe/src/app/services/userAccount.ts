import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { catchError, Observable, throwError } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

interface DocumentResponse {
  url: string;
  filename: string;
}

@Injectable({
  providedIn: 'root',
})
export class UserAccountService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(
    private http: HttpClient,
    private sessionStorage: SessionLocalStorage
  ) {}

  getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }

  insertUserAccount(userData: FormData): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/userAdd`, userData, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  insertAuthorityUser(userData: FormData): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/authorityAdd`, userData, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  deleteUser(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/deleteUser/${id}`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  getAllUsers(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/userDisplay`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  getUserById(userID: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getAuthorityUserData/${userID}`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  checkEmailExists(email: string, userId: number): Observable<boolean> {
    return this.http.get<boolean>(`${this.apiUrl}/users/check-email?email=${email}&userId=${userId}`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  updateUserAccount(userID: number, userData: FormData): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/updateAuthorityUser/${userID}`, userData, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  getUsers(page: number, pageSize: number): Observable<any> {
    return this.http
      .get<{ users: any[]; total: number }>(`${this.apiUrl}/users?page=${page}&pageSize=${pageSize}`, {
        headers: this.getHeaders(),
        withCredentials: true
      })
      .pipe(
        catchError((error) => {
          console.error('HTTP Error:', error);
          return throwError(() => new Error(error?.error?.message || 'Unknown API Error'));
        }),
      );
  }

  getUserDocument(userId: number): Observable<DocumentResponse> {
    return this.http.get<DocumentResponse>(`${this.apiUrl}/getUserDocument/${userId}`, {
      headers: this.getHeaders(),
      withCredentials: true,
    });
  }

  getUserDocuments(userId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getAuthorityUserDocuments/${userId}`, {
      headers: this.getHeaders(),
      withCredentials: true,
    });
  }

  updateAuthorityUser(userID: number, userData: FormData): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/updateAuthorityUser/${userID}`, userData, {
      headers: this.getHeaders(), 
      withCredentials: true
    });
  }

  updatePassword(email: string, newPassword: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/update-password`, { email, newPassword }, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  sendOtp(email: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/authority/forgot-password/send-otp`, { email });
  }

  verifyOtp(email: string, otp: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/authority/forgot-password/verify-otp`, { email, otp });
  }

  resetPassword(email: string, newPassword: string, confirmPassword: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/authority/forgot-password/reset-password`, { email, newPassword, confirmPassword });
  }

  addAddress(addressData: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/add-address`, addressData, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  updateAddress(addressId: string, addressData: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/update-address/${addressId}`, addressData, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  getAddresses(userId: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/get-addresses/${userId}`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }
}