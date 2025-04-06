import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TaskService } from 'src/app/services/task.service';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';

@Component({
  selector: 'app-task',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './task.component.html',
  styleUrls: ['./task.component.css']
})
export class TaskComponent implements OnInit {
  Math = Math;
  tasks: any[] = [];
  filteredTasks: any[] = [];
  displayedTasks: any[] = [];
  paginationButtons: (number | string)[] = [];
  tasksPerPage: number = 10;
  currentPage: number = 1;
  totalPages: number = 1;
  currentSearchText: string = '';
  currentStatusFilter: string = '';

  constructor(
    private route: Router,
    private taskService: TaskService
  ) {
    // Listen for navigation events to refresh tasks
    this.route.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe(() => {
        if (this.route.url === '/tasks-management') {
          this.fetchTasks(); // Refresh tasks when navigating back
        }
      });
  }

  ngOnInit(): void {
    this.fetchTasks();
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

    // Apply search filter if there's a search term
    if (this.currentSearchText) {
      tempTasks = tempTasks.filter(task => {
        // Ensure all name parts are strings and handle null/undefined
        const firstName = (task.clients.user.first_name || '').toLowerCase();
        const middleName = (task.clients.user.middle_name || '').toLowerCase();
        const lastName = (task.clients.user.last_name || '').toLowerCase();

        // Create full name with proper spacing
        const fullName = [firstName, middleName, lastName]
          .filter(name => name) // Remove empty strings
          .join(' ');

        // Split search terms to allow matching individual words
        const searchTerms = this.currentSearchText.split(/\s+/).filter(term => term);

        // Check if all search terms are present in the full name
        return searchTerms.every(term => fullName.includes(term));
      });
    }

    // Apply status filter if a status is selected
    if (this.currentStatusFilter) {
      tempTasks = tempTasks.filter(task => {
        const taskStatus = task.status?.toLowerCase();
        return taskStatus === this.currentStatusFilter;
      });
    }

    this.filteredTasks = tempTasks;
    this.currentPage = 1;
    this.updatePagination();
  }

  updatePagination() {
    this.totalPages = Math.ceil(this.filteredTasks.length / this.tasksPerPage);
    this.displayedTasks = this.filteredTasks.slice(
      (this.currentPage - 1) * this.tasksPerPage,
      this.currentPage * this.tasksPerPage
    );
    this.generatePagination();
  }

  generatePagination() {
    let maxPagesToShow = 3;
    let startPage = Math.max(1, this.currentPage - 1);
    let endPage = Math.min(this.totalPages, startPage + maxPagesToShow - 1);
  
    this.paginationButtons = [];
  
    if (startPage > 2) {
      this.paginationButtons.push('...');
    }
  
    for (let i = startPage; i <= endPage; i++) {
      this.paginationButtons.push(i);
    }
  
    if (endPage < this.totalPages - 1) {
      this.paginationButtons.push('...');
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
}