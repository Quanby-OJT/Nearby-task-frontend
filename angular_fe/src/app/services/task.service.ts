import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class TaskService {
  private apiUrl = 'http://localhost:5000/connect';

  constructor(private http: HttpClient, private sessionStorage: SessionLocalStorage) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }

  getTasks(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/displayTask`, { 
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  getTaskById(id: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/displayTask/${id}`, { 
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  disableTask(id: string): Observable<any> {
    const loggedInUserId = this.sessionStorage.getUserId();
    return this.http.patch(`${this.apiUrl}/displayTask/${id}`, { loggedInUserId }, { 
      headers: this.getHeaders(),
      withCredentials: true 
    });
  }

  getSpecializations(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/specializations`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  createSpecialization(specialization: { specialization: string; user_id: string }): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/specializations`, specialization, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }
}