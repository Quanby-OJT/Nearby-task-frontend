import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class UserConversationService {
  private apiUrl = 'https://localhost:5000/connect';

  constructor(
    private http: HttpClient,
    private sessionStorage: SessionLocalStorage
  ) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }

  getUserConversation(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getUserConversation`, {
      headers: this.getHeaders(),
      withCredentials: true,
    });
  }

  banUser(id: number, taskTakenId: number): Observable<any> {
    const userId = this.sessionStorage.getUserId();
    if (!userId) {
      return new Observable((observer) => {
        observer.error('Logged-in user ID not found');
        observer.complete();
      });
    }

    return this.http.post<any>(
      `${this.apiUrl}/banUser/${id}`,
      { loggedInUserId: Number(userId), taskTakenId },
      {
        headers: this.getHeaders(),
        withCredentials: true,
      }
    );
  }

  warnUser(id: number, taskTakenId: number): Observable<any> {
    const userId = this.sessionStorage.getUserId();
    if (!userId) {
      return new Observable((observer) => {
        observer.error('Logged-in user ID not found');
        observer.complete();
      });
    }

    return this.http.post<any>(
      `${this.apiUrl}/warnUser/${id}`,
      { loggedInUserId: Number(userId), taskTakenId },
      {
        headers: this.getHeaders(),
        withCredentials: true,
      }
    );
  }

  getTaskConversations(taskTakenId: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/messages/${taskTakenId}`, {
      headers: this.getHeaders(),
      withCredentials: true,
    });
  }
}
