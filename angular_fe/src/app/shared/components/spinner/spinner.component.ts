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
        <div class="flex flex-col justify-center items-center lg:h-[19rem] lg:w-[19rem] xl:h-[26rem] xl:w-[26rem] animate-slow-spin text-center text-2xl text-[#3C28CC] scale-150 transition-transform duration-1000">
          <img src="./assets/icons/heroicons/outline/logo.svg">
          <strong>QTask</strong>
        </div>
      </div>
    </div>
  `
})
export class SpinnerComponent {
 constructor(public loadingService: LoadingService) {}
} 