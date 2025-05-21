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

  getSpecialization(trendType: 'requested' | 'applied' = 'applied', month?: string): Observable<{
    success: boolean;
    rankedSpecializations: { specialization: string; total_requested: number; total_applied: number }[];
    monthlyTrends: { [key: string]: { [key: string]: number } };
  }> {
    return this.http.get<{
      success: boolean;
      rankedSpecializations: { specialization: string; total_requested: number; total_applied: number }[];
      monthlyTrends: { [key: string]: { [key: string]: number } };
    }>(`${this.apiUrl}/getReportAnalysisSpecialization`, {
      headers: this.getHeader(),
      withCredentials: true,
      params: { trendType, ...(month && { month }) }
    });
  }

  getTopDepositors(month?: string): Observable<{
    success: boolean;
    rankedDepositors: { userName: string; amount: number; month: string }[];
    monthlyTrends: { [userName: string]: { [month: string]: number } };
  }> {
    return this.http.get<{
      success: boolean;
      rankedDepositors: { userName: string; amount: number; month: string }[];
      monthlyTrends: { [userName: string]: { [month: string]: number } };
    }>(`${this.apiUrl}/getTopDepositors`, {
      headers: this.getHeader(),
      withCredentials: true,
      params: { ...(month && { month }) }
    });
  }

  getTopTasker(): Observable<{
    success: boolean;
    taskers: { userName: string; specialization: string; taskCount: number }[];
  }> {
    return this.http.get<{
      success: boolean;
      taskers: { userName: string; specialization: string; taskCount: number }[];
    }>(`${this.apiUrl}/getTopTasker`, {
      headers: this.getHeader(),
      withCredentials: true,
    });
  }

  getTopClient(): Observable<{
    success: boolean;
    clients: { userName: string; address: string; taskCount: number; gender: string }[];
  }> {
    return this.http.get<{
      success: boolean;
      clients: { userName: string; address: string; taskCount: number; gender: string }[];
    }>(`${this.apiUrl}/getTopClient`, {
      headers: this.getHeader(),
      withCredentials: true,
    });
  }
}
