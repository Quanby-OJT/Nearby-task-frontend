import { Component, AfterViewInit, ViewChild, ElementRef } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { AngularSvgIconModule } from 'angular-svg-icon';
import lottie from 'lottie-web';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.css'],
  imports: [AngularSvgIconModule, RouterOutlet],
})
export class AuthComponent implements AfterViewInit {
  @ViewChild('animationContainer') animationContainer!: ElementRef;

  constructor() {}

  ngAfterViewInit(): void {
    lottie.loadAnimation({
      container: this.animationContainer.nativeElement,
      path: 'assets/icons/heroicons/outline/Angular_SignupImage.json',
      renderer: 'svg',
      loop: true,
      autoplay: true,
    });
  }
}