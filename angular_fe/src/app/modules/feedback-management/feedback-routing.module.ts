import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { FeedbackComponent } from './feedback/feedback.component';

const routes: Routes = [
  {
    path: '',
    component: FeedbackComponent,
    children: [
      { path: 'feedback-management', redirectTo: 'feedback-management', pathMatch: 'full' },
      { path: 'feedback-management', component: FeedbackComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class FeedbackRoutingModule {}
