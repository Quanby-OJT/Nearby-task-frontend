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
  
  getSpecialization(trendType: 'requested' | 'applied' = 'applied', month?: string): Observable<{  success: boolean; rankedSpecializations: { specialization: string; total_requested: number; total_applied: number }[]; monthlyTrends: { [key: string]: { [key: string]: number } };}> {
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

  getTopDepositors(): Observable<{ success: boolean; rankedDepositors: { userName: string; amount: number; month: string }[];  monthlyTrends: { [userName: string]: { [month: string]: number } };}> {
    return this.http.get<{
      success: boolean;
      rankedDepositors: { userName: string; amount: number; month: string }[];
      monthlyTrends: { [userName: string]: { [month: string]: number } };
    }>(`${this.apiUrl}/getTopDepositors`, {
      headers: this.getHeader(),
      withCredentials: true,
    });
  }

  getTopTasker(): Observable<{success: boolean; taskers: { userName: string; specialization: string; taskCount: number }[];}> {
    return this.http.get<{
      success: boolean;
      taskers: { userName: string; specialization: string; taskCount: number }[];
    }>(`${this.apiUrl}/getTopTasker`, {
      headers: this.getHeader(),
      withCredentials: true,
    });
  }
}