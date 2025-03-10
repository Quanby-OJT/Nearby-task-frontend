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
  responsive: ApexResponsive[];
  legend: ApexLegend;
};

@Component({
  selector: '[user-chart-card]',
  standalone: true,
  imports: [NgApexchartsModule],
  templateUrl: './user-chart-card.component.html',
  styleUrls: ['./user-chart-card.component.css'],
})
export class UserChartCardComponent implements OnInit {
  @ViewChild('chart') chart!: ChartComponent;
  public chartOptions: ChartOptions = {
    series: [0, 0, 0, 0], // Initialize with default counts
    chart: {
      type: 'pie',
    },
    labels: ['Admin', 'Moderator', 'Client', 'Tasker'],
    responsive: [
      {
        breakpoint: 480,
        options: {
          chart: {
            width: 400,
          },
          legend: {
            position: 'bottom',
          },
        },
      },
    ],
    legend: {
      position: 'right',
    },
  };

  constructor(private userAccountService: UserAccountService) {}

  ngOnInit(): void {
    this.fetchUserRoleDistribution();
  }

  private fetchUserRoleDistribution(): void {
    this.userAccountService.getAllUsers().subscribe({
      next: (response) => {
        const users = response.users || [];
        const roleDistribution = this.calculateRoleDistribution(users);
        this.updateChartSeries(roleDistribution);
      },
      error: (error) => {
        console.error('Error fetching users:', error);
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
        // Optionally handle unknown roles (e.g., log or ignore)
      }
    });

    return roleCount; // Return raw counts
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