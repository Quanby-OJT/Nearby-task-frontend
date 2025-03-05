import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class DataService {
  private userID: Number = 0;
  private userRole = new BehaviorSubject<string>('');

  setUserID(data: Number) {
    this.userID = data;
  }

  getUserID() {
    return this.userID;
  }

  setUserRole(data: string) {
    this.userRole.next(data);
  }

  getUserRole() {
    return this.userRole.asObservable();
  }
}
