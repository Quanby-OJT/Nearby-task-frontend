import { MenuItem } from '../models/menu.model';

export class Menu {
  public static pages: MenuItem[] = [
    {
      //group : base
      group: '',
      separator: false,
      items: [
        {
          icon: 'assets/icons/heroicons/outline/chart-pie.svg',
          label: 'Dashboard',
          route: '/dashboard',
          role: ['admin', 'moderator'],
        },

        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'User Management',
          route: '/user-management',
          role: ['admin', 'moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'User Communication',
          route: '/user-communication',
          role: ['moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'Tasks Management',
          route: '/tasks-management',
          role: ['moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'Payment Reviews',
          route: '/payment-reviews',
          role: ['moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'User Complaints',
          route: '/complaints',
          role: ['moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'Feedback Management',
          route: '/feedback-management',
          role: ['moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'User Logs',
          route: '/user-logs',
          role: ['moderator', 'admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/lock-closed.svg',
          label: 'Reports & Analytics',
          route: '/reports',
          role: ['moderator', 'admin'],
        },

        // {
        //   icon: 'assets/icons/heroicons/outline/lock-closed.svg',
        //   label: 'Auth',
        //   route: '/auth',
        //   children: [
        //     { label: 'Sign up', route: '/auth/sign-up' },
        //     { label: 'Sign in', route: '/auth/sign-in' },
        //     { label: 'Forgot Password', route: '/auth/forgot-password' },
        //     { label: 'New Password', route: '/auth/new-password' },
        //     { label: 'Two Steps', route: '/auth/two-steps' },
        //   ],
        // },
        // {
        //   icon: 'assets/icons/heroicons/outline/exclamation-triangle.svg',
        //   label: 'Errors',
        //   route: '/errors',
        //   children: [
        //     { label: '404', route: '/errors/404' },
        //     { label: '500', route: '/errors/500' },
        //   ],
        // },
        // {
        //   icon: 'assets/icons/heroicons/outline/cube.svg',
        //   label: 'Components',
        //   route: '/components',
        //   children: [{ label: 'Table', route: '/components/table' }],
        // },
      ],
    },

    // {
    //   group: 'Collaboration',
    //   separator: true,
    //   items: [
    //     {
    //       icon: 'assets/icons/heroicons/outline/download.svg',
    //       label: 'Download',
    //       route: '/download',
    //     },
    //     {
    //       icon: 'assets/icons/heroicons/outline/gift.svg',
    //       label: 'Gift Card',
    //       route: '/gift',
    //     },
    //     {
    //       icon: 'assets/icons/heroicons/outline/users.svg',
    //       label: 'Users',
    //       route: '/users',
    //     },
    //   ],
    // },
  ];
}
