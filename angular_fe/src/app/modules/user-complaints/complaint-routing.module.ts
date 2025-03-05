import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

import { ComplaintsComponent } from './complaints/complaints.component';

const routes: Routes = [
  {
    path: '',
    component: ComplaintsComponent,
    children: [
      { path: 'complaints', redirectTo: 'complaints', pathMatch: 'full' },
      { path: 'complaints', component: ComplaintsComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class ComplaintsRoutingModule {}
