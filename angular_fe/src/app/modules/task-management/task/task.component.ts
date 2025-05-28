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
import { Task } from 'src/model/task'; 

@Component({
  selector: 'app-task',
  standalone: true,
  imports: [CommonModule, FormsModule, AngularSvgIconModule],
  templateUrl: './task.component.html',
  styleUrls: ['./task.component.css']
})
export class TaskComponent implements OnInit {
  Math = Math;
  tasks: Task[] = [];
  filteredTasks: Task[] = [];
  displayedTasks: Task[] = [];
  paginationButtons: (number | string)[] = [];
  tasksPerPage: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  currentSearchText: string = '';
  currentStatusFilter: string = '';
  userRole: string | undefined;
  placeholderRows: any[] = [];
  isLoading: boolean = true;
  sortModes: { [key: string]: 'default' | 'asc' | 'desc' } = {
    client: 'default',
    taskTitle: 'default',
    specialization: 'default',
    location: 'default',
    proposedPrice: 'default'
  };
  @Output() onCheck = new EventEmitter<boolean>();
  @Output() onSort = new EventEmitter<'asc' | 'desc'>();

  constructor(
    private route: Router,
    private taskService: TaskService,
    private authService: AuthService
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
    this.isLoading = true;
    this.fetchTasks();
    this.authService.userInformation().subscribe(
      (response: any) => {
        this.userRole = response.user.user_role;
        this.isLoading = false;
      },
      (error: any) => {
        console.error('Error fetching user role:', error);
        this.isLoading = false;
      }
    );
  }

  fetchTasks(): void {
    this.taskService.getTasks().subscribe(
      (response: { tasks: any[] }) => {
        console.log('Fetched tasks:', response.tasks);
        this.tasks = response.tasks.map(task => ({
          ...task,
          actionByUser: task.action_by_user ? {
            first_name: task.action_by_user.first_name,
            middle_name: task.action_by_user.middle_name || '',
            last_name: task.action_by_user.last_name
          } : undefined,
          action_reason: task.action_reason || ''
        }));
        this.filteredTasks = this.tasks;
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

    // Apply search filter
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

    // Apply status filter
    if (this.currentStatusFilter) {
      tempTasks = tempTasks.filter(task => {
        const taskStatus = task.status?.toLowerCase();
        return taskStatus === this.currentStatusFilter;
      });
    }

    // Apply sorting
    for (const column in this.sortModes) {
      if (this.sortModes[column] !== 'default') {
        tempTasks.sort((a, b) => {
          let valueA: string | number;
          let valueB: string | number;
          switch (column) {
            case 'client':
              valueA = `${a.clients.user.first_name || ''} ${a.clients.user.middle_name || ''} ${a.clients.user.last_name || ''}`.toLowerCase();
              valueB = `${b.clients.user.first_name || ''} ${b.clients.user.middle_name || ''} ${b.clients.user.last_name || ''}`.toLowerCase();
              break;
            case 'taskTitle':
              valueA = (a.task_title || '').toLowerCase();
              valueB = (b.task_title || '').toLowerCase();
              break;
            case 'specialization':
              valueA = (a.specialization || '').toLowerCase();
              valueB = (b.specialization || '').toLowerCase();
              break;
            case 'location':
              valueA = (a.location || '').toLowerCase();
              valueB = (b.location || '').toLowerCase();
              break;
            case 'proposedPrice':
              valueA = a.proposed_price;
              valueB = b.proposed_price;
              break;
            default:
              return 0;
          }
          if (column === 'proposedPrice') {
            if (this.sortModes[column] === 'asc') {
              return (valueA as number) - (valueB as number); // Smallest to biggest
            } else { // 'desc'
              return (valueB as number) - (valueA as number); // Biggest to smallest
            }
          } else {
            if (this.sortModes[column] === 'asc') {
              return (valueA as string).localeCompare(valueB as string);
            } else { // 'desc'
              return (valueB as string).localeCompare(valueA as string);
            }
          }
        });
        break; // Only sort by one column at a time
      }
    }

    // Default sorting by created_at if no column is selected
    if (Object.values(this.sortModes).every(mode => mode === 'default')) {
      tempTasks.sort((a, b) => {
        const dateA = new Date(a.created_at || '1970-01-01');
        const dateB = new Date(b.created_at || '1970-01-01');
        return dateB.getTime() - dateA.getTime(); // Newest to oldest
      });
    }

    this.filteredTasks = tempTasks;
    this.currentPage = 1;
    this.updatePagination();
  }

  public toggle(event: Event) {
    const value = (event.target as HTMLInputElement).checked;
    this.onCheck.emit(value);
  }

  public toggleSort(column: string) {
    switch (this.sortModes[column]) {
      case 'default':
        this.sortModes[column] = 'desc'; // Start with biggest to smallest
        break;
      case 'desc':
        this.sortModes[column] = 'asc'; // Then smallest to biggest
        break;
      case 'asc':
        this.sortModes[column] = 'default'; // Back to default
        break;
    }
    // Reset other columns to default
    for (const key in this.sortModes) {
      if (key !== column) {
        this.sortModes[key] = 'default';
      }
    }
    this.applyFilters();
  }

  updatePagination() {
    this.totalPages = Math.ceil(this.filteredTasks.length / this.tasksPerPage);
    this.displayedTasks = this.filteredTasks.slice(
      (this.currentPage - 1) * this.tasksPerPage,
      this.currentPage * this.tasksPerPage
    );
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
    const headers = ['No', 'Client Id', 'Client', 'Task Title', 'Specialization', 'Proposed Price', 'Location', 'Urgent', 'Status', 'Action Reason'];
    const rows = this.displayedTasks.map((task, index) => {
      const row = [
        index + 1,
        task.clients.client_id ?? '',
        `"${task.clients.user.first_name} ${task.clients.user.middle_name || ''} ${task.clients.user.last_name}"`,
        `"${task.task_title || ''}"`,
        task.specialization || '',
        task.proposed_price,
        `"${task.location || ''}"`,
        task.urgent ? 'Yes' : 'No',
        task.status || 'null',
        `"${task.action_reason || ''}"`
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

    try {
      doc.addImage('./assets/icons/heroicons/outline/NearbTask.png', 'PNG', 140, 35, 28, 25); 
    } catch (e) {
      console.error('Failed to load NearbyTasks.png:', e);
    }

    try {
      doc.addImage('./assets/icons/heroicons/outline/Quanby.png', 'PNG', 260, 35, 26, 25);
    } catch (e) {
      console.error('Failed to load Quanby.png:', e);
    }

   // Nearby Task Part
   const title = 'Nearby Task';
   doc.setFontSize(20);
   doc.setTextColor('#170A66');
   doc.text(title, 170, 52);

   // Line Part
   doc.setDrawColor(0, 0, 0);
   doc.setLineWidth(0.2);
   doc.line(30, 70, 415, 70);

    // Task Manager Part
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    doc.text('Task Management', 30, 90);

    // Date and Time Part
    const currentDate = new Date();
    const formattedDate = currentDate.toLocaleString('en-US', {
      month: '2-digit',
      day: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    }).replace(/,/, ', ');
    console.log('Formatted Date:', formattedDate); 

    // Date and Time Position and Size
    doc.setFontSize(12);
    doc.setTextColor('#000000');
    console.log('Rendering date at position x=400, y=90'); 
    doc.text(formattedDate, 310, 90); 

    const columns = ['No', 'Client Id', 'Client', 'Task Title', 'Specialization', 'Proposed Price', 'Location', 'Urgent', 'Status', 'Action Reason'];
    const rows = this.displayedTasks.map((task, index) => [
      index + 1,
      task.clients.client_id ?? '',
      `${task.clients.user.first_name} ${task.clients.user.middle_name || ''} ${task.clients.user.last_name}`,
      task.task_title || '',
      task.specialization || '',
      task.proposed_price,
      task.location || '',
      task.urgent ? 'Yes' : 'No',
      task.status || 'null',
      task.action_reason || ''
    ]);
    autoTable(doc, {
      startY: 125,
      head: [columns],
      body: rows,
      theme: 'grid',
      styles: { fontSize: 8, cellPadding: 5, textColor: 'black' },
      headStyles: { fillColor: [60, 33, 146], textColor: 'white' },
    });
    doc.save('Tasks.pdf');
  }
}