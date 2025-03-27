import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class ReportService {
  private apiUrl = 'http://localhost:5000/connect';
  constructor(
    private http: HttpClient,
    private sessionStorage: SessionLocalStorage
  ){}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
    });
  }


  getReport(): Observable<any>{
    return this.http.get<any>(`${this.apiUrl}/getReports`, {
      headers: this.getHeaders(),
      withCredentials: true
    }).pipe(
      tap(response => {
        console.log('Response from backend:', response);
      })
    );
  }
}