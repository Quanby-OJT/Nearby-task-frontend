import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TaskService } from 'src/app/services/task.service';
import { CommonModule } from '@angular/common';
import { AngularSvgIconModule } from 'angular-svg-icon';
import Swal from 'sweetalert2';

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

  async disableTask() {
    if (!this.task?.task_id) return;
  
    const { value: reason } = await Swal.fire({
      title: 'Are you sure?',
      text: 'Please provide a reason for closing this task.',
      input: 'text',
      inputPlaceholder: 'Enter reason here...',
      showCancelButton: true,
      confirmButtonText: 'Confirm',
      cancelButtonText: 'Cancel',
      inputValidator: (value) => {
        if (!value) {
          return 'You need to provide a reason!';
        }
        return null;
      },
      inputAttributes: {
        style: 'width: auto; max-width: auto;',
      },
      willOpen: () => {
        const confirmButton = Swal.getConfirmButton();
        const input = Swal.getInput();
        if (confirmButton && input) {
          confirmButton.disabled = true;
          input.oninput = () => {
            confirmButton.disabled = !input.value.trim();
          };
        }
      }
    });
  
    if (reason) {
      this.taskService.disableTask(this.task.task_id, reason).subscribe({
        next: () => {
          console.log('Task disabled successfully');
          this.task.status = 'Closed';
          this.cdr.detectChanges();
          this.router.navigate(['tasks-management']);
        },
        error: (err) => console.error('Error disabling task:', err)
      });
    }
  }
}