import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LoadingService } from 'src/app/services/loading.service';

@Component({
  selector: 'app-spinner',
  standalone: true,
  imports: [CommonModule],
  template: `
  <div *ngIf="loadingService.isLoading$ | async" class="fixed inset-0 z-50 flex flex-col justify-center items-center bg-white">
    <div class="m-auto">
      <div class="flex flex-col justify-center items-center lg:h-[30rem] lg:w-[50rem] xl:h-[50rem] xl:w-[30rem] animate-slow-spin text-center text-2xl text-[#3C28CC] scale-100 transition-transform duration-5000">
        <img src="./assets/icons/heroicons/outline/logo.svg" class="w-48 h-48">
        <strong>QTask</strong>
      </div>
    </div>
  </div>
  `,
})
export class SpinnerComponent {
 constructor(public loadingService: LoadingService) {}
} 