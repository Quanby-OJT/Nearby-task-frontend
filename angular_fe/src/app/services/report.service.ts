import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root',
})
export class ReportService {
  private apiUrl = 'http://localhost:5000/connect';
  constructor(private http: HttpClient){}

  getReport(): Observable<any>{
    return this.http.get<any>(`${this.apiUrl}/getReports`).pipe(
      tap(response => {
        console.log('Response from backend:', response);
      })
    );
  }
}