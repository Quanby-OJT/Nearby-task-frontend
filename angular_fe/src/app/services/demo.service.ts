import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class DemoService {
  private apiUrl = `${environment.apiUrl}`;

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }

  constructor(private http: HttpClient, private sessionStorage: SessionLocalStorage) {}
  getAllUsers(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/display`, { headers: this.getHeaders(), withCredentials: true });
  }

  insertUser(userData: FormData): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/add`, userData, { headers: this.getHeaders(), withCredentials: true });
  }
}
