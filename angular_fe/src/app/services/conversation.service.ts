import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class UserConversationService {

  private apiUrl = 'http://localhost:5000/connect';
  
  constructor(private http: HttpClient) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
    });
  }

  // Get the conversation from the backend server
  getUserLogs(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getUserConversation`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }

  banUser(id: number): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/banUser/${id}`, {}, {
      headers: this.getHeaders(),
      withCredentials: true 
    });
  }

  warnUser(id: number): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/warnUser/${id}`, {}, {
      headers: this.getHeaders(),
      withCredentials: true 
    });
  }

  getTaskConversations(taskTakenId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/messages/${taskTakenId}`, {
      headers: this.getHeaders(),
      withCredentials: true
    });
  }
}