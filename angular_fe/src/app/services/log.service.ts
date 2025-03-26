import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class UserLogService {
  // URL where the logs come from
  private apiUrl = `${environment.apiUrl}/connect`;

  constructor(private http: HttpClient, private sessionStorage: SessionLocalStorage) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }

  // Get the logs from the backend server
  getUserLogs(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/displayLogs`, { 
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }
}