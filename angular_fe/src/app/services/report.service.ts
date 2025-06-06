import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root'
})
export class ReportService {
  private apiUrl = 'https://localhost:5000/connect';

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

  updateReportStatus(reportId: number, status: boolean, reason: string, actionType: 'ban' | 'unban'): Observable<any> {
    const userId = this.sessionStorage.getUserId();
    const parsedUserId = userId ? parseInt(userId, 10) : 0;
    if (!parsedUserId || isNaN(parsedUserId)) {
      throw new Error('The Current Logged In User Has No Session!');
    }
    const requestBody = { status, reportId, moderatorId: parsedUserId, reason, actionType };
    console.log('Update Report Status Request Body:', requestBody);
    return this.http.patch(`${this.apiUrl}/reports/${reportId}`, requestBody, {
      headers: this.getHeader(),
      withCredentials: true
    });
  }
}