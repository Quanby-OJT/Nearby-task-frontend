import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { TaskComponent } from './task/task.component';
import { TaskReportedListComponent } from './task/task-reported-list/task-reported-list.component';
import { CreateSpecializationComponent } from './task/create-specialization/create-specialization.component';


const routes: Routes = [
  {
    path: '',
    children: [
      { path: '', redirectTo: '', pathMatch: 'full' },
      { path: '', component: TaskComponent },
      { path: 'task-disable/:id', component: TaskReportedListComponent },
      { path: 'create-specialization', component: CreateSpecializationComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class TaskRoutingModule {}
