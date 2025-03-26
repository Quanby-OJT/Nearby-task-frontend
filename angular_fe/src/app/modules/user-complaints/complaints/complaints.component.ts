import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ClientComplaintComponent } from './client-complaint/client-complaint.component';
import { TaskerComplaintComponent } from './tasker-complaint/tasker-complaint.component';


@Component({
  selector: 'app-complaints',
  standalone: true,
  imports: [
    CommonModule,
    ClientComplaintComponent,
    TaskerComplaintComponent
  ],
  templateUrl: './complaints.component.html',
  styleUrls: ['./complaints.component.css']
})
export class ComplaintsComponent {

  
}