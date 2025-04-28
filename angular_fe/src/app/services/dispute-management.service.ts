import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { SessionLocalStorage } from 'src/services/sessionStorage';

export class DisputeManagementService{

  private apiUrl = 'http://localhost:5000/connect';

  constructor(private http: HttpClient, private sessionStorage: SessionLocalStorage) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }

  getDisputes(): Observable<any> {
    return this.http.get<any>(`${environment.apiUrl}/disputes`, { headers: this.getHeaders(), withCredentials: true });
  }

  getDisputeById(disputeId: number): Observable<any> {
    return this.http.get<any>(`${environment.apiUrl}/disputes/${disputeId}`, { headers: this.getHeaders(), withCredentials: true });
  }

  updateDisputeStatus(disputeId: number, status: string): Observable<any> {
    return this.http.patch<any>(`${environment.apiUrl}/disputes/${disputeId}`, { status }, { headers: this.getHeaders(), withCredentials: true });
  }
}
