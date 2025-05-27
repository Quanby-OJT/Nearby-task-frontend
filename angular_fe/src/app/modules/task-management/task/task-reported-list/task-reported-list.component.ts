import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TaskService } from 'src/app/services/task.service';
import { CommonModule } from '@angular/common';
import { AngularSvgIconModule } from 'angular-svg-icon';
import Swal from 'sweetalert2'; // Import SweetAlert2

@Component({
  selector: 'app-task-reported-list',
  standalone: true,
  imports: [CommonModule, AngularSvgIconModule],
  templateUrl: './task-reported-list.component.html',
  styleUrls: ['./task-reported-list.component.css']
})
export class TaskReportedListComponent implements OnInit {
  task: any;

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private taskService: TaskService,
    private cdr: ChangeDetectorRef 
  ) {}

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.taskService.getTaskById(id).subscribe({
        next: (response) => {
          this.task = response.tasks;
        },
        error: (err) => {
          console.error('Error fetching task:', err);
          this.router.navigate(['/error']);
        }
      });
    }
  }

  taskList() {
    this.router.navigate(['tasks-management']);
  }

  async disableTask(event: Event) { // Add event parameter
    event.preventDefault(); // Prevent form submission to stop page reload

    if (!this.task?.task_id) return;

    // Show SweetAlert2 popup with input field
    const { value: reason } = await Swal.fire({
      title: 'Close This Task',
      html: `
        <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for this action</label>
        <input id="reason-input" class="swal2-input" placeholder="Enter reason" />
      `,
      showCancelButton: true,
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

        // Disable confirm button initially
        if (confirmButton) {
          confirmButton.disabled = true;
        }

        // Enable confirm button only when input has a value
        reasonInput.addEventListener('input', () => {
          if (confirmButton) {
            confirmButton.disabled = !reasonInput.value.trim();
          }
        });
      }
    });

    // If the user confirms and provides a reason, proceed with disabling the task
    if (reason) {
      this.taskService.disableTask(this.task.task_id, reason).subscribe({
        next: () => {
          console.log('Task disabled successfully');
          this.task.status = 'Closed';
          this.cdr.detectChanges();
          Swal.fire('Success', 'Task has been closed successfully', 'success');
          this.router.navigate(['tasks-management']);
        },
        error: (err) => {
          console.error('Error disabling task:', err);
          Swal.fire('Error', 'Failed to close the task', 'error');
        }
      });
    }
  }
}