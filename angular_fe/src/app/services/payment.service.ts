import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Injectable({
  providedIn: 'root',
})
export class PaymentService {
  
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

  getPaymentLogs(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/displayPaymentLogs`, {
      headers: this.getHeader(),
      withCredentials: true
    });
  }
}