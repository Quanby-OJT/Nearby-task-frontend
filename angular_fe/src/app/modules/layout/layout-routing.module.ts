import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LayoutComponent } from './layout.component';

const routes: Routes = [
  {
    path: 'dashboard',
    component: LayoutComponent,
    loadChildren: () => import('../dashboard/pages/dashboard.module').then((m) => m.DashboardModule),
  },
  {
    path: 'user-management',
    component: LayoutComponent,
    loadChildren: () => import('../user-management/user-routing.module').then((m) => m.UserRoutingModule),
  },
  {
    path: 'user-communication',
    component: LayoutComponent,
    loadChildren: () =>
      import('../user-communication/user-communication-routing.module').then((m) => m.UserCommunicationModule),
  },
  {
    path: 'tasks-management',
    component: LayoutComponent,
    loadChildren: () => import('../task-management/task-routing.module').then((m) => m.TaskRoutingModule),
  },
  {
    path: 'payment-reviews',
    component: LayoutComponent,
    loadChildren: () => import('../payment-reviews/payment-routing.module').then((m) => m.PaymentRoutingModule),
  },
  {
    path: 'complaints',
    component: LayoutComponent,
    loadChildren: () => import('../user-complaints/complaint-routing.module').then((m) => m.ComplaintsRoutingModule),
  },
  {
    path: 'feedback-management',
    component: LayoutComponent,
    loadChildren: () => import('../feedback-management/feedback-routing.module').then((m) => m.FeedbackRoutingModule),
  },

  {
    path: 'user-logs',
    component: LayoutComponent,
    loadChildren: () => import('../log/log-routing.module').then((m) => m.LogRoutingModule),
  },

  {
    path: 'reports',
    component: LayoutComponent,
    loadChildren: () => import('../report/report-routing.module').then((m) => m.ReportRoutingModule),
  },
  {
    path: 'settings',
    component: LayoutComponent,
    loadChildren: () => import('../setting/setting-routing.module').then((m) => m.SettingRoutingModule),
  },

  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: '**', redirectTo: 'error/404' },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class LayoutRoutingModule {}
