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
  
  getSpecialization(): Observable<any> {
    return this.http.get(`${this.apiUrl}/getReportAnalysisSpecialization`, {
      headers: this.getHeader(),
      withCredentials: true
    });
  }
}