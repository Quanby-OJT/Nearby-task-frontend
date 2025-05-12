import { CommonModule } from '@angular/common';
import { Component, OnInit, ViewChild } from '@angular/core';
import { ChartComponent, NgApexchartsModule } from 'ng-apexcharts';
import { ApexNonAxisChartSeries, ApexChart, ApexResponsive, ApexLegend } from 'ng-apexcharts';
import { UserAccountService } from 'src/app/services/userAccount'; 

// Define the interface for role distribution
interface RoleDistribution {
  admin: number;
  moderator: number;
  client: number;
  tasker: number;
}

export type ChartOptions = {
  series: ApexNonAxisChartSeries;
  chart: ApexChart;
  labels: string[];
  colors: string[];
  responsive: ApexResponsive[];
  legend: ApexLegend;
};

@Component({
  selector: '[user-chart-card]',
  standalone: true,
  imports: [NgApexchartsModule, CommonModule],
  templateUrl: './user-chart-card.component.html',
  styleUrls: ['./user-chart-card.component.css'],
})
export class UserChartCardComponent implements OnInit {
  @ViewChild('chart') chart!: ChartComponent;
  public chartOptions: ChartOptions = {
    series: [0, 0, 0, 0], // Initialize with default counts
    chart: {
      type: 'pie',
      width: '100%',
      height: 300, // Set a default height for initial rendering
    },
    labels: ['Admin', 'Moderator', 'Client', 'Tasker'],
    colors: ['#8586EC', '#8586EC', '#C2C3F6', '#E1E1FA'],
    responsive: [
      {
        breakpoint: 480,
        options: {
          chart: {
            width: '100%',
            height: 200, // Adjusted height for smaller screens
          },
          legend: {
            position: 'bottom',
          },
        },
      },
      {
        breakpoint: 1024,
        options: {
          chart: {
            width: '100%',
            height: 250, // Adjusted height for medium screens
          },
          legend: {
            position: 'right',
          },
        },
      },
      {
        breakpoint: 1280,
        options: {
          chart: {
            width: '100%',
            height: 400, // Adjusted height for larger screens
          },
          legend: {
            position: 'right',
          },
        },
      },
    ],
    legend: {
      position: 'right',
    },
  };

  // loading state
  public isLoading: boolean = true; 

  constructor(private userAccountService: UserAccountService) {}

  ngOnInit(): void {
    this.fetchUserRoleDistribution();
  }

  private fetchUserRoleDistribution(): void {
    this.isLoading = true; // Set loading to true before fetching
    this.userAccountService.getAllUsers().subscribe({
      next: (response) => {
        const users = response.users || [];
        const roleDistribution = this.calculateRoleDistribution(users);
        this.updateChartSeries(roleDistribution);
        this.isLoading = false; 
      },
      error: (error) => {
        console.error('Error fetching users:', error);
        this.isLoading = false; 
      },
    });
  }

  private calculateRoleDistribution(users: any[]): RoleDistribution {
    const roleCount: RoleDistribution = {
      admin: 0,
      moderator: 0,
      client: 0,
      tasker: 0,
    };

    // Define a mapping of possible role variations to normalized roles
    const roleMap: { [key: string]: keyof RoleDistribution } = {
      'admin': 'admin',
      'administrator': 'admin', 
      'moderator': 'moderator',
      'mod': 'moderator', 
      'client': 'client',
      'customer': 'client', 
      'tasker': 'tasker',
      'worker': 'tasker', 
      'ADMIN': 'admin',
      'MODERATOR': 'moderator',
      'CLIENT': 'client',
      'TASKER': 'tasker',
    };

    users.forEach(user => {
      const role = user.user_role?.toString().toLowerCase().trim(); // Normalize to lowercase and trim whitespace
      if (role && roleMap.hasOwnProperty(role)) {
        const normalizedRole = roleMap[role];
        roleCount[normalizedRole]++;
      } else {
        console.warn(`Unknown role encountered: ${user.user_role}`);
      }
    });

    return roleCount;
  }

  private updateChartSeries(roleDistribution: RoleDistribution): void {
    this.chartOptions.series = [
      roleDistribution.admin,
      roleDistribution.moderator,
      roleDistribution.client,
      roleDistribution.tasker,
    ];
  }

  public getTotalUsers(): number {
    return this.chartOptions.series.reduce((sum, count) => sum + count, 0);
  }
}