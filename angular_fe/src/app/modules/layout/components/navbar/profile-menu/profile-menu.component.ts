import { animate, state, style, transition, trigger } from '@angular/animations';
import { NgClass, NgIf } from '@angular/common';
import { Component, Input, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { ThemeService } from '../../../../../core/services/theme.service';
import { ClickOutsideDirective } from '../../../../../shared/directives/click-outside.directive';
import { AuthService } from 'src/app/services/auth.service';
import { SignInComponent } from 'src/app/modules/auth/pages/sign-in/sign-in.component';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { toast } from 'ngx-sonner';
import { Users } from 'src/model/user-management';
import { DataService } from 'src/services/dataStorage';
@Component({
  selector: 'app-profile-menu',
  templateUrl: './profile-menu.component.html',
  styleUrls: ['./profile-menu.component.css'],
  imports: [ClickOutsideDirective, NgClass, RouterLink, AngularSvgIconModule, NgIf],
  animations: [
    trigger('openClose', [
      state(
        'open',
        style({
          opacity: 1,
          transform: 'translateY(0)',
          visibility: 'visible',
        }),
      ),
      state(
        'closed',
        style({
          opacity: 0,
          transform: 'translateY(-20px)',
          visibility: 'hidden',
        }),
      ),
      transition('open => closed', [animate('0.2s')]),
      transition('closed => open', [animate('0.2s')]),
    ]),
  ],
})
export class ProfileMenuComponent implements OnInit {
  constructor(
    public themeService: ThemeService,
    private authService: AuthService,
    private signinService: SignInComponent,
    private sessionStorage: SessionLocalStorage,
    private dataservicec: DataService,
  ) {}
  public isOpen = false;
  user: Users = {} as Users;

  public profileMenu = [
    {
      title: 'Your Profile',
      icon: './assets/icons/heroicons/outline/user-circle.svg',
      link: '/profile',
    },
    {
      title: 'Settings',
      icon: './assets/icons/heroicons/outline/cog-6-tooth.svg',
      link: '/settings',
    },
    {
      title: 'Log out',
      icon: './assets/icons/heroicons/outline/logout.svg',
      action: () => this.logout(),
    },
  ];

  logout(): void {
    const user_id = this.sessionStorage.getUserId();
    this.signinService.logout(user_id);
  }

  public themeColors = [
    {
      name: 'base',
      code: '#e11d48',
    },
    {
      name: 'yellow',
      code: '#f59e0b',
    },
    {
      name: 'green',
      code: '#22c55e',
    },
    {
      name: 'blue',
      code: '#3b82f6',
    },
    {
      name: 'orange',
      code: '#ea580c',
    },
    {
      name: 'red',
      code: '#cc0022',
    },
    {
      name: 'violet',
      code: '#6d28d9',
    },
  ];

  public themeMode = ['light', 'dark'];

  ngOnInit(): void {
    this.authService.userInformation().subscribe(
      (response: any) => {
        console.log('User Information:', response.user);
        this.user = response.user;
        // this.user_role = response.user_role;
        console.log('This is user role' + response.user.user_role);
        this.dataservicec.setUserRole(response.user.user_role);
      },
      (error: any) => {
        console.error('Error fetching users:', error);
        this.handleRequestError(error);
      },
    );
  }
  handleRequestError(error: any): void {
    console.error('API Request Error:', error);
    toast.error(error?.message || 'An unknown error occurred');
  }
  public toggleMenu(): void {
    this.isOpen = !this.isOpen;
  }

  toggleThemeMode() {
    this.themeService.theme.update((theme) => {
      const mode = !this.themeService.isDark ? 'dark' : 'light';
      return { ...theme, mode: mode };
    });
  }

  toggleThemeColor(color: string) {
    this.themeService.theme.update((theme) => {
      return { ...theme, color: color };
    });
  }
}
