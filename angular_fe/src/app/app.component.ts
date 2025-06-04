import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { NgxSonnerToaster } from 'ngx-sonner';
import { ThemeService } from './core/services/theme.service';
import { LoadingService } from './services/loading.service';
import { SpinnerComponent } from './shared/components/spinner/spinner.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, NgxSonnerToaster, SpinnerComponent],
  template: `
    <app-spinner></app-spinner>
    <router-outlet></router-outlet>
  `
})
export class AppComponent {
  title = 'NearByTask';

  constructor(
    public themeService: ThemeService, 
    public loadingService: LoadingService) {}
}
