import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ChartOptions } from '../../../../../shared/models/chart-options';
import { TaskService } from 'src/app/services/task.service';
import { ChartComponent } from 'ng-apexcharts';
import { CommonModule } from '@angular/common';
@Component({
  selector: '[nft-chart-card]',
  templateUrl: './nft-chart-card.component.html',
  imports: [AngularSvgIconModule, NgApexchartsModule, CommonModule],
  standalone: true
})
export class NftChartCardComponent implements OnInit, OnDestroy {
  @ViewChild('chart') chart: ChartComponent | undefined;
  public chartOptions: ChartOptions;
  public selectedFilter: 'daily' | 'monthly' | 'yearly' = 'daily';
  private tasks: any[] = [];
  public isLoading: boolean = true; 

  constructor(private taskService: TaskService) {
    this.chartOptions = {
      series: [],
      chart: {
        type: 'area',
        height: 150,
        toolbar: {
          show: false
        },
        sparkline: {
          enabled: false
        }
      },
      dataLabels: {
        enabled: false
      },
      fill: {
        type: 'gradient',
        gradient: {
          shadeIntensity: 1,
          opacityFrom: 0.4,
          opacityTo: 0.2,
          stops: [15, 120, 100]
        }
      },
      stroke: {
        curve: 'smooth',
        width: 2,
        colors: ['#5F50E7']
      },
      xaxis: {
        categories: [],
        labels: {
          show: true,
          formatter: (val: string) => val
        }
      },
      yaxis: {
        show: true,
        labels: {
          formatter: (val: number) => Math.floor(val).toString()
        }
      },
      grid: {
        show: false
      },
      tooltip: {
        enabled: true,
        y: {
          formatter: (val: number) => `${val} tasks`
        }
      },
      colors: ['#5F50E7'],
      legend: {
        show: false
      },
      states: {
        normal: { filter: { type: 'none' } },
        hover: { filter: { type: 'lighten' } },
        active: { filter: { type: 'darken' } }
      },
      title: {
        text: undefined
      },
      subtitle: {
        text: undefined
      },
      theme: {
        mode: 'light'
      },
      annotations: {},
      responsive: [],
      plotOptions: {},
      markers: {
        size: 0
      }
    };
  }

  ngOnInit(): void {
    this.isLoading = true; 
    this.taskService.getTasks().subscribe({
      next: (response) => {
        this.tasks = response.tasks || [];
        console.log('Tasks loaded:', this.tasks);
        this.updateChartData();
        this.isLoading = false; 
      },
      error: (err) => {
        console.error('Error fetching tasks:', err);
        this.tasks = [];
        this.updateChartData();
        this.isLoading = false; 
      }
    });
  }

  ngOnDestroy(): void {}

  setFilter(filter: 'daily' | 'monthly' | 'yearly') {
    this.selectedFilter = filter;
    this.updateChartData();
  }

  private updateChartData() {
    let series = [{ name: 'Created Tasks', data: [] as number[] }];
    let xaxis = { categories: [] as string[], labels: { show: true, formatter: (val: string) => val } };

    if (!this.tasks || this.tasks.length === 0) {
      series = [{ name: 'Created Tasks', data: [0, 0, 0, 0, 0] }];
      xaxis = { categories: this.generateEmptyCategories(), labels: { show: true, formatter: (val: string) => val } };
    } else {
      let groupBy: 'day' | 'month' | 'year';
      let labelFormatter: (val: string) => string;
      let categories: string[];
      let data: number[];

      switch (this.selectedFilter) {
        case 'daily':
          groupBy = 'day';
          labelFormatter = (val: string) => {
            const date = new Date(val);
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
          };
          const taskCountsDaily = this.groupTasksBy(this.tasks, groupBy);
          const dailyResult = this.generateFiveCategories(taskCountsDaily, groupBy);
          categories = dailyResult.categories;
          data = dailyResult.data;
          break;

        case 'monthly':
          groupBy = 'month';
          labelFormatter = (val: string) => {
            const [year, month] = val.split('-');
            const date = new Date(parseInt(year), parseInt(month) - 1);
            return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
          };
          const taskCountsMonthly = this.groupTasksBy(this.tasks, groupBy);
          const monthlyResult = this.generateFiveCategories(taskCountsMonthly, groupBy);
          categories = monthlyResult.categories;
          data = monthlyResult.data;
          break;

        case 'yearly':
          groupBy = 'year';
          labelFormatter = (val: string) => val;
          const taskCountsYearly = this.groupTasksBy(this.tasks, groupBy);
          const yearlyResult = this.generateFiveCategories(taskCountsYearly, groupBy);
          categories = yearlyResult.categories;
          data = yearlyResult.data;
          break;

        default:
          groupBy = 'day';
          labelFormatter = (val: string) => {
            const date = new Date(val);
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
          };
          const taskCountsDefault = this.groupTasksBy(this.tasks, groupBy);
          const defaultResult = this.generateFiveCategories(taskCountsDefault, groupBy);
          categories = defaultResult.categories;
          data = defaultResult.data;
      }

      series = [{ name: 'Created Tasks', data }];
      xaxis = {
        categories,
        labels: { show: true, formatter: labelFormatter }
      };

      console.log(`${this.selectedFilter} categories:`, categories);
      console.log(`${this.selectedFilter} data:`, data);
    }

    this.chartOptions.series = series;
    this.chartOptions.xaxis = xaxis;

    // Force chart update
    if (this.chart) {
      this.chart.updateSeries(series, true);
      this.chart.updateOptions({ xaxis }, true);
    }
  }

  private groupTasksBy(tasks: any[], groupBy: 'day' | 'month' | 'year') {
    const counts: { [key: string]: number } = {};
    const keyGenerators = {
      day: (date: Date) => date.toISOString().split('T')[0],
      month: (date: Date) => `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`,
      year: (date: Date) => date.getFullYear().toString(),
    };

    tasks.forEach(task => {
      if (!task.created_at) return;
      const date = new Date(task.created_at);
      if (isNaN(date.getTime())) return;
      const key = keyGenerators[groupBy](date);
      counts[key] = (counts[key] || 0) + 1;
    });

    return counts;
  }

  private generateFiveCategories(taskCounts: { [key: string]: number }, groupBy: 'day' | 'month' | 'year') {
    const categories: string[] = [];
    const data: number[] = [];
    const sortedKeys = Object.keys(taskCounts).sort();
    
    
    const now = new Date('2025-04-16'); 
    let currentKey: string;
    if (groupBy === 'day') {
      currentKey = now.toISOString().split('T')[0]; 
    } else if (groupBy === 'month') {
      currentKey = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}`;
    } else {
      currentKey = now.getFullYear().toString(); 
    }

    // Get up to 3 past periods with data
    let pastKeys = sortedKeys.filter(key => key < currentKey).slice(-3);
    
    // Add past periods
    pastKeys.forEach(key => {
      categories.push(key);
      data.push(taskCounts[key] || 0);
    });

    // Add current period (4th slot)
    if (!categories.includes(currentKey)) {
      categories.push(currentKey);
      data.push(taskCounts[currentKey] || 0);
    }

    // Add future period (5th slot)
    let futureKey: string;
    if (groupBy === 'day') {
      const nextDay = new Date(now);
      nextDay.setDate(now.getDate() + 1);
      futureKey = nextDay.toISOString().split('T')[0]; // e.g., '2025-04-17'
    } else if (groupBy === 'month') {
      const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
      futureKey = `${nextMonth.getFullYear()}-${(nextMonth.getMonth() + 1).toString().padStart(2, '0')}`; // e.g., '2025-05'
    } else {
      futureKey = (now.getFullYear() + 1).toString(); // e.g., '2026'
    }
    categories.push(futureKey);
    data.push(0);

    // Trim to exactly 5 records if more than 5
    if (categories.length > 5) {
      categories.splice(0, categories.length - 5);
      data.splice(0, data.length - 5);
    }

    // Pad with empty periods if less than 5
    while (categories.length < 5) {
      let prevKey: string;
      if (groupBy === 'day') {
        const firstDate = new Date(categories[0]);
        firstDate.setDate(firstDate.getDate() - 1);
        prevKey = firstDate.toISOString().split('T')[0];
      } else if (groupBy === 'month') {
        const [year, month] = categories[0].split('-');
        const prevMonth = new Date(parseInt(year), parseInt(month) - 2, 1);
        prevKey = `${prevMonth.getFullYear()}-${(prevMonth.getMonth() + 1).toString().padStart(2, '0')}`;
      } else {
        prevKey = (parseInt(categories[0]) - 1).toString();
      }
      categories.unshift(prevKey);
      data.unshift(0);
    }

    return { categories, data };
  }

  private generateEmptyCategories(): string[] {
    const categories: string[] = [];
    const now = new Date('2025-04-16');
    if (this.selectedFilter === 'daily') {
      for (let i = -3; i <= 1; i++) {
        const date = new Date(now);
        date.setDate(now.getDate() + i);
        categories.push(date.toISOString().split('T')[0]);
      }
    } else if (this.selectedFilter === 'monthly') {
      for (let i = -3; i <= 1; i++) {
        const date = new Date(now.getFullYear(), now.getMonth() + i, 1);
        categories.push(`${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`);
      }
    } else {
      for (let i = -3; i <= 1; i++) {
        categories.push((now.getFullYear() + i).toString());
      }
    }
    return categories;
  }
}