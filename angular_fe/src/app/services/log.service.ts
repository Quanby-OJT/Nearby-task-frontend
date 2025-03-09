import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class UserLogService {
  // URL where the logs come from
  private apiUrl = 'http://localhost:5000/connect/displayLogs';

  constructor(private http: HttpClient) {}

  // Get the logs from the backend server
  getUserLogs(): Observable<any> {
    return this.http.get<any>(this.apiUrl);
  }
}