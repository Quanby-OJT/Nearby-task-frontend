import { Component, EventEmitter, Output } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';

@Component({
  selector: '[app-table-header]',
  imports: [AngularSvgIconModule],
  templateUrl: './table-header.component.html',
  styleUrl: './table-header.component.css',
})
export class UserTableHeaderComponent {
  @Output() onCheck = new EventEmitter<boolean>();
  @Output() onSort = new EventEmitter<'asc' | 'desc'>();

  sortDirection: 'asc' | 'desc' = 'desc'; // Default to newest-to-oldest

  public toggle(event: Event) {
    const value = (event.target as HTMLInputElement).checked;
    this.onCheck.emit(value);
  }

  public toggleSort() {
    this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    this.onSort.emit(this.sortDirection);
  }
}