import { Component } from '@angular/core';
import { ClientComplainTabComponent } from './client-complain-tab/client-complain-tab.component';
import { TaskerComplainTabComponent } from './tasker-complain-tab/tasker-complain-tab.component';
import { CommonModule } from '@angular/common';
import { ComplainCardComponent } from './complain-card/complain-card.component';
import { ComplainCardResolveComponent } from './complain-card-resolve/complain-card-resolve.component';

@Component({
  selector: 'app-complaints',
  imports: [
    ClientComplainTabComponent, 
    TaskerComplainTabComponent,
    CommonModule,
    ComplainCardComponent,
    ComplainCardResolveComponent,
  ],
  templateUrl: './complaints.component.html',
  styleUrl: './complaints.component.css'
})
export class ComplaintsComponent {

currentTab: String = "ClientTab";

switchTab(activeTab: string){

  this.currentTab = activeTab;

  }
}