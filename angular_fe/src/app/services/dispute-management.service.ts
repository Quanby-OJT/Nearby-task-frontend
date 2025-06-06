import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class DisputeManagementService {
  private apiUrl = 'https://localhost:5000/connect'

  constructor(
    private http: HttpClient,
    private sessionStorage: SessionLocalStorage
  ) { }

  private getHeader(): HttpHeaders {
    return new HttpHeaders({
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    })
  }

  getAllDisputes(): Observable<any> {
    return this.http.get(`${this.apiUrl}/get-all-disputes`, {
      headers: this.getHeader(),
      withCredentials: true
    })
  }

  updateADispute(id: number, task_taken_id: number, task_id: number, task_status: string, moderator_action: string, addl_dispute_notes?: string): Observable<any> {
    const moderator_id = this.sessionStorage.getUserId();
    return this.http.put(`${this.apiUrl}/update-dispute/${id}`, {
      task_taken_id,
      task_status,
      task_id,
      moderator_id,
      moderator_action,
      addl_dispute_notes
    }, {
      headers: this.getHeader(),
      withCredentials: true
    })
  }

  archiveADispute(id: number) {
    return this.http.delete(`${this.apiUrl}/archive-dispute/${id}`, {
      headers: this.getHeader(),
      withCredentials: true
    })
  }
}
