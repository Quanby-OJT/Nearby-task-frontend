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
  @Output() onSort = new EventEmitter<'default' | 'asc' | 'desc'>();

  sortState: 'default' | 'asc' | 'desc' = 'default'; 

  public toggle(event: Event) {
    const value = (event.target as HTMLInputElement).checked;
    this.onCheck.emit(value);
  }

  public toggleSort() {
    this.sortState = this.sortState === 'default' ? 'asc' : this.sortState === 'asc' ? 'desc' : 'default';
    this.onSort.emit(this.sortState);
  }
}