import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-create-specialization',
  templateUrl: './create-specialization.component.html',
  styleUrls: ['./create-specialization.component.css']
})
export class CreateSpecializationComponent {
  constructor(private router: Router) {}

  taskListPage() {
    this.router.navigate(['tasks-management']);
  }
}