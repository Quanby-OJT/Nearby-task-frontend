import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class UserConversationService {
  
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

  // Get the conversation from the backend server
  getUserLogs(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getUserConversation`,{
      headers: this.getHeader(),
      withCredentials: true
    });
  }
}