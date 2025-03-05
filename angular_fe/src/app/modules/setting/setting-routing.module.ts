import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { SettingComponent } from './setting/setting.component';

const routes: Routes = [
  {
    path: '',
    component: SettingComponent,
    children: [
      { path: 'settings', redirectTo: 'settings', pathMatch: 'full' },
      { path: 'settings', component: SettingComponent },
      { path: '**', redirectTo: 'errors/404' },
    ],
  },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class SettingRoutingModule {}
