import { Component, OnInit } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { TaskService } from 'src/app/services/task.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-create-specialization',
  imports: [RouterLink, FormsModule, CommonModule],
  templateUrl: './create-specialization.component.html',
  styleUrls: ['./create-specialization.component.css']
})
export class CreateSpecializationComponent implements OnInit {
  specializationName: string = '';
  specializations: any[] = [];
  submitted: boolean = false;

  constructor(private router: Router, private taskService: TaskService) {}

  ngOnInit(): void {
    this.loadSpecializations();
  }

  loadSpecializations(): void {
    this.taskService.getSpecializations().subscribe({
      next: (response) => {
        this.specializations = response.specializations; // Adjust for backend response format
      },
      error: (error) => {
        console.error('Error fetching specializations:', error);
      }
    });
  }

  addSpecialization(): void {
    this.submitted = true;
    if (this.specializationName) {
      this.taskService.createSpecialization({ specialization: this.specializationName }).subscribe({
        next: () => {
          this.specializationName = '';
          this.submitted = false;
          this.loadSpecializations(); 
        },
        error: (error) => {
          console.error('Error adding specialization:', error);
        }
      });
    }
  }

  taskListPage(): void {
    this.router.navigate(['tasks-management']);
  }
}