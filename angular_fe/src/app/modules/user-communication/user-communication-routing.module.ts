import { NgModule, OnInit } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { UserCommunicationComponent } from './user-communication/user-communication.component';

const routes: Routes = [
  {
    path: '',
    component: UserCommunicationComponent,
    children: [
      { path: 'user-communication', redirectTo: 'user-communication', pathMatch: 'full' },
      { path: 'user-communication', component: UserCommunicationComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class UserCommunicationModule {}
