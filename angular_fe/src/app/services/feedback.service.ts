import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SessionLocalStorage } from 'src/services/sessionStorage';


@Injectable({
    providedIn: 'root',
})
export class FeedbackService {

    private apiUrl = 'https://localhost:5000/connect';

    constructor(
        private http: HttpClient,
        private sessionStorage: SessionLocalStorage
    ) {}


    private getHeader(): HttpHeaders {
        return new HttpHeaders({
            'Authorization': `Bearer ${this.sessionStorage.getSessionToken()}`
        })
    }

    getFeedback(): Observable<any> {
        return this.http.get(`${this.apiUrl}/get-all-tasker-feedback`, { 
            headers: this.getHeader(),
            withCredentials: true
        });
    }
}