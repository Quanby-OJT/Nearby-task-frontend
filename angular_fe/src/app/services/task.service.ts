import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment'; // Use environment API URL
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class TaskService {
  private apiUrl = `${environment.apiUrl}/connect`; // Use environment variable

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
      withCredentials: true // This enables sending cookies with the request
    });
  }

  getTaskById(id: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/displayTask/${id}`, { 
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }

  disableTask(id: string): Observable<any> {
    return this.http.put(`${this.apiUrl}/disableTask/${id}`, {}, { 
      headers: this.getHeaders(),
      withCredentials: true // This enables sending cookies with the request
    });
  }
}
