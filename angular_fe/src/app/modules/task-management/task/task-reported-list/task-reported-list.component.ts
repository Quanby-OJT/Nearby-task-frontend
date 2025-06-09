import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TaskService } from 'src/app/services/task.service';
import { CommonModule } from '@angular/common';
import { AngularSvgIconModule } from 'angular-svg-icon';
import Swal from 'sweetalert2';
import { AuthService } from 'src/app/services/auth.service';

@Component({
  selector: 'app-task-reported-list',
  standalone: true,
  imports: [CommonModule, AngularSvgIconModule],
  templateUrl: './task-reported-list.component.html',
  styleUrls: ['./task-reported-list.component.css']
})
export class TaskReportedListComponent implements OnInit {
  task: any;
  userRole: string | undefined;

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    private taskService: TaskService,
    private cdr: ChangeDetectorRef,
    private authService: AuthService
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
    this.authService.userInformation().subscribe(
      (response: any) => {
        this.userRole = response.user.user_role;
      },
      (error: any) => {
        console.error('Error fetching user role:', error);
      }
    );
  }

  taskList() {
    this.router.navigate(['tasks-management']);
  }

  async disableTask(event: Event) { 
    event.preventDefault(); 

    if (!this.task?.task_id) return;

    if (this.userRole === 'Moderator' && this.task.action_by_user?.user_role === 'Admin') {
      await Swal.fire('Error', "You don't have authority to take action here since this action is made by an admin", 'error');
      return;
    }

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

  async activateTask(event: Event) { 
    event.preventDefault(); 

    if (!this.task?.task_id) return;

    if (this.userRole === 'Moderator' && this.task.action_by_user?.user_role === 'Admin') {
      await Swal.fire('Error', "You don't have authority to take action here since this action is made by an admin", 'error');
      return;
    }

    const { value: reason } = await Swal.fire({
      title: 'Activate This Task',
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
      this.taskService.activateTask(this.task.task_id, reason).subscribe({
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