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
          role: ['Admin', 'Moderator'],
        },

        {
          icon: 'assets/icons/heroicons/outline/user-circle.svg',
          label: 'User Management',
          route: '/user-management',
          role: ['Admin', 'Moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/users.svg',
          label: 'User Communication',
          route: '/user-communication',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/cube.svg',
          label: 'Tasks Management',
          route: '/tasks-management',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/folder.svg',
          label: 'Payment Reviews',
          route: '/payment-reviews',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/shield-exclamation.svg',
          label: 'User Complaints',
          route: '/complaints',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/exclamation-triangle.svg',
          label: 'Dispute Management',
          route: '/dispute-management',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/menu.svg',
          label: 'Feedback Management',
          route: '/feedback-management',
          role: ['Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/eye.svg',
          label: 'User Logs',
          route: '/user-logs',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/view-grid.svg',
          label: 'Reports & Analytics',
          route: '/reports',
          role: ['Admin'],
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
