import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DisputeManagementComponent } from './dispute-management.component';

const routes: Routes = [
    {
      path: '',
      component: DisputeManagementComponent,
      children: [
        { path: 'dispute-management', redirectTo: 'dispute-management', pathMatch: 'full' },
        { path: 'dispute-management', component: DisputeManagementComponent },
        { path: '**', redirectTo: 'errors/404' },
      ],
    },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DisputeRoutingModule { }
