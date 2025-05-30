import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { TaskService } from 'src/app/services/task.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import Swal from 'sweetalert2';
import { SessionLocalStorage } from 'src/services/sessionStorage';

@Component({
  selector: 'app-create-specialization',
  imports: [FormsModule, CommonModule],
  templateUrl: './create-specialization.component.html',
  styleUrls: ['./create-specialization.component.css']
})
export class CreateSpecializationComponent implements OnInit {
  specializationName: string = '';
  specializations: any[] = [];
  submitted: boolean = false;

  constructor(
    private router: Router,
    private taskService: TaskService,
    private sessionStorage: SessionLocalStorage
  ) {}

  ngOnInit(): void {
    this.loadSpecializations();
  }

  loadSpecializations(): void {
    this.taskService.getSpecializations().subscribe({
      next: (response) => {
        this.specializations = response.specializations;
      },
      error: (error) => {
        console.error('Error fetching specializations:', error);
      }
    });
  }

  async addSpecialization(): Promise<void> {
    this.submitted = true;
    if (this.specializationName) {
      // Show SweetAlert2 modal to capture reason
      const { value: reason } = await Swal.fire({
        title: 'Add Specialization',
        html: `
          <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for adding this specialization</label>
          <input id="reason-input" class="swal2-input" placeholder="Enter reason" />
        `,
        showCancelButton: true,
        confirmButtonColor: '#5F50E7',
        cancelButtonColor: '#d33',
        confirmButtonText: 'Confirm',
        cancelButtonText: 'Cancel',
        preConfirm: () => {
          const reasonInput = (document.getElementById('reason-input') as HTMLInputElement).value;
          if (!reasonInput) {
            Swal.showValidationMessage('Please provide a reason for this action');
          }
          return reasonInput;
        },
        willOpen: () => {
          const confirmButton = Swal.getConfirmButton();
          const reasonInput = document.getElementById('reason-input') as HTMLInputElement;
          if (confirmButton) {
            confirmButton.disabled = true;
          }
          reasonInput.addEventListener('input', () => {
            if (confirmButton) {
              confirmButton.disabled = !reasonInput.value.trim();
            }
          });
        }
      });

      if (reason) {
        const userId = this.sessionStorage.getUserId();
        this.taskService.createSpecialization({ specialization: this.specializationName, user_id: userId, reason }).subscribe({
          next: () => {
            this.specializationName = '';
            this.submitted = false;
            this.loadSpecializations();
            Swal.fire('Added!', 'Specialization has been added.', 'success');
          },
          error: (error) => {
            console.error('Error adding specialization:', error);
            Swal.fire('Error', error.error?.error || 'Failed to add specialization.', 'error');
          }
        });
      }
    }
  }

  taskListPage(): void {
    this.router.navigate(['tasks-management']);
  }
}