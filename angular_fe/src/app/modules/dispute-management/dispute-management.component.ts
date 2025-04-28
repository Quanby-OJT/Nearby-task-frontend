import { Component } from '@angular/core';
import { DisputeTableComponent } from './dispute-table/dispute-table.component';
import { DisputeSearchComponent } from './dispute-search/dispute-search.component';
import { DisputeFilterComponent } from './dispute-filter/dispute-filter.component';

@Component({
  selector: 'app-dispute-management',
  standalone: true,
  imports: [DisputeTableComponent, DisputeSearchComponent, DisputeFilterComponent],
  templateUrl: './dispute-management.component.html',
  styleUrl: './dispute-management.component.css'
})
export class DisputeManagementComponent {

}
