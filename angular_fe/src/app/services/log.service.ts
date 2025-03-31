import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class UserLogService {
  
  private apiUrl = 'http://localhost:5000/connect';
  
  constructor(
    private http: HttpClient,
    private sessionStorage: SessionLocalStorage
  ) {}


  private getHeader(): HttpHeaders {
      return new HttpHeaders({
        'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
      })
  }

  // Get the logs from the backend server
  getUserLogs(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/displayLogs`, {
      headers: this.getHeader(),
      withCredentials: true
    });
  }
}