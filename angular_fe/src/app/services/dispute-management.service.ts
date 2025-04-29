import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class DisputeManagementService {
  private apiUrl = 'http://localhost:5000/connect'

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

  getDisputeDetails(id: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/get-dispute/${id}`, {
      headers: this.getHeader(),
      withCredentials: true
    })
  }

  updateADispute(id: number, task_status: string, moderator_action: string, addl_dispute_notes?: string): Observable<any> {
    return this.http.patch(`${this.apiUrl}/update-dispute/${id}`, {
      task_status,
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
