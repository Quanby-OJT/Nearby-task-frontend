import { NgModule, Component } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LogComponent } from './log/log.component';

const routes: Routes = [
  {
    path: '',
    children: [
      { path: '', redirectTo: '', pathMatch: 'full' },
      { path: '', component: LogComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class LogRoutingModule {}
