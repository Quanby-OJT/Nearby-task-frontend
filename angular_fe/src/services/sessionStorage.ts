import { Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class SessionLocalStorage {
  session = signal<object>({});
  constructor() {}
  sessionId = Object.keys(this.session)[0];
  user_id = signal<Number>(0);

  setSessionLocal(value: any): void {
    this.session.set(value);
  }

  setSession(value: any): void {
    sessionStorage.setItem('session', JSON.stringify(value));
    localStorage.setItem('session', JSON.stringify(value));
  }

  getSession(): any {
    // return Object.keys(this.session())[0];
    // const storedSession = sessionStorage.getItem('session');
    // return storedSession ? JSON.parse(storedSession) : this.session();
    return localStorage.getItem('session');
  }

  getSessionId(): string | null {
    const sessionData = this.getSession();
    return sessionData ? Object.keys(sessionData)[0] : null;
  }

  setUserId(value: any): void {
    this.user_id.set(value);
    localStorage.setItem('user_id', value);
  }

  getUserId(): any {
    return this.user_id();
  }
}
