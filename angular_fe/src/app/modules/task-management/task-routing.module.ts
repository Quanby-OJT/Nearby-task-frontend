import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { TaskComponent } from './task/task.component';

const routes: Routes = [
  {
    path: '',
    component: TaskComponent,
    children: [
      { path: 'task-management', redirectTo: 'task-management', pathMatch: 'full' },
      { path: 'task-management', component: TaskComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class TaskRoutingModule {}
