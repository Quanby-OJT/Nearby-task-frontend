import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Output } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: '[app-table-header]',
  imports: [AngularSvgIconModule, CommonModule],
  templateUrl: './table-header.component.html',
  styleUrl: './table-header.component.css',
})
export class UserTableHeaderComponent {
  @Output() onCheck = new EventEmitter<boolean>();
  @Output() onSort = new EventEmitter<{ column: 'profile' | 'email'; state: 'default' | 'asc' | 'desc' }>();

  profileSortState: 'default' | 'asc' | 'desc' = 'default';
  emailSortState: 'default' | 'asc' | 'desc' = 'default';

  public toggle(event: Event) {
    const value = (event.target as HTMLInputElement).checked;
    this.onCheck.emit(value);
  }

  public toggleProfileSort() {
    this.profileSortState = this.profileSortState === 'default' ? 'asc' : this.profileSortState === 'asc' ? 'desc' : 'default';
    this.emailSortState = 'default'; // Reset email sort
    this.onSort.emit({ column: 'profile', state: this.profileSortState });
  }

  public toggleEmailSort() {
    this.emailSortState = this.emailSortState === 'default' ? 'asc' : this.emailSortState === 'asc' ? 'desc' : 'default';
    this.profileSortState = 'default'; // Reset profile sort
    this.onSort.emit({ column: 'email', state: this.emailSortState });
  }
}