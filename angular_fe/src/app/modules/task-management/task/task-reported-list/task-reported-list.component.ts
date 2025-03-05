import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TaskService } from 'src/app/services/task.service';
import { CommonModule } from '@angular/common';
import { AngularSvgIconModule } from 'angular-svg-icon';

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
        next: (task) => this.task = task,
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

  disableTask() {
    if (!this.task?.job_post_id) return;
  
    this.taskService.disableTask(this.task.job_post_id).subscribe({
      next: () => {
        console.log('Task disabled successfully');
        this.task.status = 'disabled';
        this.cdr.detectChanges(); // Force UI update
      },
      error: (err) => console.error('Error disabling task:', err)
    });
    this.router.navigate(['tasks-management']);
  }
}