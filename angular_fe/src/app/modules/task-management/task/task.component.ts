import { Component, EventEmitter, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TaskService } from 'src/app/services/task.service';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { saveAs } from 'file-saver';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { AuthService } from 'src/app/services/auth.service';

@Component({
  selector: 'app-task',
  standalone: true,
  imports: [CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './task.component.html',
  styleUrls: ['./task.component.css']
})
export class TaskComponent implements OnInit {
  Math = Math;
  tasks: any[] = [];
  filteredTasks: any[] = [];
  displayedTasks: any[] = [];
  paginationButtons: (number | string)[] = [];
  tasksPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  currentSearchText: string = '';
  currentStatusFilter: string = '';
  userRole: string | undefined;
  // New property for placeholder rows
  placeholderRows: any[] = [];

  @Output() onCheck = new EventEmitter<boolean>();
  @Output() onSort = new EventEmitter<'asc' | 'desc'>();
  sortDirection: 'asc' | 'desc' = 'desc';

  constructor(
    private route: Router,
    private taskService: TaskService,
    private authService: AuthService // Assuming you have an AuthService to get user role
  ) {
    this.route.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe(() => {
        if (this.route.url === '/tasks-management') {
          this.fetchTasks();
        }
      });
  }

  ngOnInit(): void {
    this.fetchTasks();

    this.authService.userInformation().subscribe(
      (response: any) => {
        this.userRole = response.user.user_role;
      },
      (error: any) => {
        console.error('Error fetching user role:', error);
      }
    );
  }

  fetchTasks(): void {
    this.taskService.getTasks().subscribe(
      (response) => {
        console.log('Fetched tasks:', response.tasks);
        this.tasks = response.tasks;
        this.filteredTasks = response.tasks;
        this.updatePagination();
      },
      (error) => console.error('Error fetching tasks:', error)
    );
  }

  searchTasks(event: Event) {
    this.currentSearchText = (event.target as HTMLInputElement).value.trim().toLowerCase();
    this.applyFilters();
  }

  filterTasks(event: Event) {
    this.currentStatusFilter = (event.target as HTMLSelectElement).value.toLowerCase();
    this.applyFilters();
  }

  applyFilters() {
    let tempTasks = [...this.tasks];

    if (this.currentSearchText) {
      tempTasks = tempTasks.filter(task => {
        const firstName = (task.clients.user.first_name || '').toLowerCase();
        const middleName = (task.clients.user.middle_name || '').toLowerCase();
        const lastName = (task.clients.user.last_name || '').toLowerCase();
        const fullName = [firstName, middleName, lastName].filter(name => name).join(' ');
        const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);
        return searchTerms.every(term => fullName.includes(term));
      });
    }

    if (this.currentStatusFilter) {
      tempTasks = tempTasks.filter(task => {
        const taskStatus = task.status?.toLowerCase();
        return taskStatus === this.currentStatusFilter;
      });
    }

    tempTasks.sort((a, b) => {

      const dateA = a.created_at ? new Date(a.created_at) : null;
      const dateB = b.created_at ? new Date(b.created_at) : null;


      if (!dateA || isNaN(dateA.getTime())) {
        console.warn(`Invalid created_at for task ID ${a.task_id}:`, a.created_at);
        return 1;
      }
      if (!dateB || isNaN(dateB.getTime())) {
        console.warn(`Invalid created_at for task ID ${b.task_id}:`, b.created_at);
        return -1;
      }

      // Compare dates
      const timeDiff = this.sortDirection === 'asc'
        ? dateA.getTime() - dateB.getTime()
        : dateB.getTime() - dateA.getTime();

      // If dates are equal, sort by task_id as secondary key
      if (timeDiff === 0) {
        return this.sortDirection === 'asc'
          ? a.task_id - b.task_id // Smaller task_id first in asc
          : b.task_id - a.task_id; // Larger task_id first in desc
      }

      return timeDiff;
    });

    // Log sorted tasks for debugging
    console.log(`Sorted tasks (${this.sortDirection}):`, tempTasks.map(task => ({
      task_id: task.task_id,
      created_at: task.created_at,
      client: `${task.clients.user.first_name} ${task.clients.user.last_name}`
    })));

    this.filteredTasks = tempTasks;
    this.currentPage = 1;
    this.updatePagination();
  }

  public toggle(event: Event) {
    const value = (event.target as HTMLInputElement).checked;
    this.onCheck.emit(value);
  }

  public toggleSort() {
    this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    this.onSort.emit(this.sortDirection);
    this.applyFilters();
  }

  updatePagination() {
    this.totalPages = Math.ceil(this.filteredTasks.length / this.tasksPerPage);
    this.displayedTasks = this.filteredTasks.slice(
      (this.currentPage - 1) * this.tasksPerPage,
      this.currentPage * this.tasksPerPage
    );
    // Calculate and generate placeholder rows
    const placeholderCount = this.tasksPerPage - this.displayedTasks.length;
    this.placeholderRows = Array(placeholderCount).fill({});
    this.generatePagination();
  }

  generatePagination() {
    let maxPagesToShow = 3;
    let startPage = Math.max(1, this.currentPage - 1);
    let endPage = Math.min(this.totalPages, startPage + maxPagesToShow - 1);

    this.paginationButtons = [];

    for (let i = startPage; i <= endPage; i++) {
      this.paginationButtons.push(i);
    }
  }

  changeTasksPerPage(event: Event) {
    this.tasksPerPage = parseInt((event.target as HTMLSelectElement).value, 10);
    this.currentPage = 1;
    this.updatePagination();
  }

  goToPage(page: number | string) {
    const pageNumber = typeof page === 'string' ? parseInt(page, 10) : page;
    if (pageNumber >= 1 && pageNumber <= this.totalPages) {
      this.currentPage = pageNumber;
      this.updatePagination();
    }
  }

  disableTask(taskId: string) {
    this.route.navigate(['tasks-management/task-disable', taskId]);
  }

  createSpecialization() {
    this.route.navigate(['tasks-management/create-specialization']);
  }

  exportCSV() {
    const headers = ['No', 'Client Id', 'Client', 'Task Title', 'Specialization', 'Proposed Price', 'Location', 'Urgent', 'Status'];
    const rows = this.displayedTasks.map((task, index) => {
      const row = [
        index + 1,
        task?.clients?.client_id ?? task.client_id ?? '',
        `"${task.clients.user.first_name} ${task.clients.user.middle_name || ''} ${task.clients.user.last_name}"`,
        `"${task.task_title || ''}"`,
        task.specialization || '',
        task.proposed_price || 0,
        `"${task.location || ''}"`,
        task.urgent ? 'Yes' : 'No',
        task.status || 'null',
      ];
      return row;
    });
    const csvContent = [headers.join(','), ...rows.map((row) => row.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    saveAs(blob, 'Tasks.csv');
  }

  exportPDF() {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'px',
      format: 'a4',
    });
    const title = 'Task Management';
    doc.setFontSize(20);
    doc.text(title, 170, 45);
    const columns = ['No', 'Client Id', 'Client', 'Task Title', 'Specialization', 'Proposed Price', 'Location', 'Urgent', 'Status'];
    const rows = this.displayedTasks.map((task, index) => [
      index + 1,
      task?.clients?.client_id ?? task.client_id ?? '',
      `${task.clients.user.first_name} ${task.clients.user.middle_name || ''} ${task.clients.user.last_name}`,
      task.task_title || '',
      task.specialization || '',
      task.proposed_price || 0,
      task.location || '',
      task.urgent ? 'Yes' : 'No',
      task.status || 'null',
    ]);
    autoTable(doc, {
      startY: 100,
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('Tasks.pdf');
  }
}
