import { Component } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { UserTableFilterService } from 'src/services/user-table-filter';

@Component({
  selector: 'app-table-action',
  imports: [AngularSvgIconModule],
  templateUrl: './table-action.component.html',
  styleUrl: './table-action.component.css',
})
export class UserTableActionComponent {
  constructor(public filterService: UserTableFilterService) {}

  onSearchChange(value: Event) {
    const input = value.target as HTMLInputElement;
    this.filterService.searchField.set(input.value);
  }

  onStatusChange(value: Event) {
    const selectElement = value.target as HTMLSelectElement;
    this.filterService.statusField.set(selectElement.value);
  }

  onRoleChange(value: Event) {
    const selectElement = value.target as HTMLSelectElement;
    this.filterService.roleField.set(selectElement.value);
  }

  onOnlineChange(value: Event) {
    const selectElement = value.target as HTMLSelectElement;
    this.filterService.onlineField.set(selectElement.value);
  }
}