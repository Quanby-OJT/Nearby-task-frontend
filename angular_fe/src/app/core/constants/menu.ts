import { MenuItem } from '../models/menu.model';

export class Menu {
  public static pages: MenuItem[] = [
    {
      //group : base
      group: '',
      separator: false,
      items: [
        {
          icon: 'assets/icons/heroicons/outline/dashboard.svg',
          label: 'Dashboard',
          route: '/dashboard',
          role: ['Admin', 'Moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/user-mangement.svg',
          label: 'User Management',
          route: '/user-management',
          role: ['Admin', 'Moderator'],
        },
        {
          icon: 'assets/icons/heroicons/outline/conversation.svg',
          label: 'User Communication',
          route: '/user-communication',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/task.svg',
          label: 'Tasks Management',
          route: '/tasks-management',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/payment-review.svg',
          label: 'Payment Reviews',
          route: '/payment-reviews',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/complains.svg',
          label: 'User Complaints',
          route: '/complaints',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/gavel-dispute.svg',
          label: 'Dispute Management',
          route: '/dispute-management',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/feedbacks.svg',
          label: 'Feedback Management',
          route: '/feedback-management',
          role: ['Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/logs.svg',
          label: 'User Logs',
          route: '/user-logs',
          role: ['Moderator', 'Admin'],
        },
        {
          icon: 'assets/icons/heroicons/outline/graphs.svg',
          label: 'Reports & Analytics',
          route: '/reports',
          role: ['Admin'],
        },
      ],
    },
  ];
}
