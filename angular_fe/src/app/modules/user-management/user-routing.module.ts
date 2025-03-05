import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { UsersComponent } from './users/users.component';
import { AddUserComponent } from './add-user/add-user.component';
import { UpdateUserComponent } from './update-user/update-user.component';
import { ReviewComponent } from './review/review.component';

const routes: Routes = [
  {
    path: '',
    children: [
      { path: '', redirectTo: '', pathMatch: 'full' },
      { path: '', component: UsersComponent },
      { path: 'add-user', component: AddUserComponent },
      { path: 'update-user', component: UpdateUserComponent },
      { path: 'review-user', component: ReviewComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class UserRoutingModule {}
