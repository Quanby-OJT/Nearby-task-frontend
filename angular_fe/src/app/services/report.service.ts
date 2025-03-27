import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root'
})
export class ReportService {
  private apiUrl = 'http://localhost:5000/connect';

  constructor(
    private http: HttpClient,
    private sessionStorage: SessionLocalStorage
  ) {}

  private getHeader(): HttpHeaders {
    return new HttpHeaders({
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }
  
  getReport(): Observable<any> {
    return this.http.get(`${this.apiUrl}/getReports`, {
      headers: this.getHeader(),
      withCredentials: true
    });
  }

  updateReportStatus(reportId: number, status: boolean): Observable<any> {
    return this.http.patch(`${this.apiUrl}/reports/${reportId}`, { status }, {
      headers: this.getHeader(),
      withCredentials: true
    });
  }
}