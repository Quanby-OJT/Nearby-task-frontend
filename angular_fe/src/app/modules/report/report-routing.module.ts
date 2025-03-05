import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ReportComponent } from './report/report.component';

const routes: Routes = [
  {
    path: '',
    component: ReportComponent,
    children: [
      { path: 'reports', redirectTo: 'reports', pathMatch: 'full' },
      { path: 'reports', component: ReportComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class ReportRoutingModule {}
