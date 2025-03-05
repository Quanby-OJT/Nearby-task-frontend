import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserCommunicationModule } from './user-communication-routing.module';
import { HttpClientModule } from '@angular/common/http';

@NgModule({
  declarations: [],
  imports: [CommonModule, UserCommunicationModule, HttpClientModule],
})
export class UserCommunicationRoutingModule {}
