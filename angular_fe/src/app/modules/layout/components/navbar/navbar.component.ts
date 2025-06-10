import { Component, OnInit, OnDestroy } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { MenuService } from '../../services/menu.service';
import { NavbarMenuComponent } from './navbar-menu/navbar-menu.component';
import { NavbarMobileComponent } from './navbar-mobile/navbar-mobilecomponent';
import { ProfileMenuComponent } from './profile-menu/profile-menu.component';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { interval, Subscription } from 'rxjs';
import { AuthService } from 'src/app/services/auth.service';
import { Users } from 'src/model/user-management';

@Component({
  selector: 'app-navbar',
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.css'],
  imports: [AngularSvgIconModule, NavbarMenuComponent, ProfileMenuComponent, NavbarMobileComponent],
})
export class NavbarComponent implements OnInit, OnDestroy {
  currentDateTime: string = '';
  user: Users = {} as Users;
  private timeSubscription: Subscription | undefined;

  constructor(
    private menuService: MenuService,
    private sessionStorage: SessionLocalStorage,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    // Initialize user info
    this.updateUserInfo();
    
    // Start time updates
    this.updateDateTime();
    this.timeSubscription = interval(1000).subscribe(() => {
      this.updateDateTime();
    });
  }

  ngOnDestroy(): void {
    if (this.timeSubscription) {
      this.timeSubscription.unsubscribe();
    }
  }

  private updateDateTime(): void {
    const now = new Date();
    const month = now.toLocaleString('en-US', { month: 'long' });
    const day = now.getDate().toString().padStart(2, '0');
    const year = now.getFullYear();
    const time = now.toLocaleString('en-US', {
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
      hour12: true
    });
    this.currentDateTime = `${month}-${day}-${year}, ${time}`;
  }

  private updateUserInfo(): void {
    this.authService.userInformation().subscribe(
      (response: any) => {
        console.log('User Information:', response.user);
        this.user = response.user;
      },
      (error: any) => {
        console.error('Error fetching user information:', error);
      }
    );
  }

  public toggleMobileMenu(): void {
    this.menuService.showMobileMenu = !this.menuService.showMobileMenu;
  }
}