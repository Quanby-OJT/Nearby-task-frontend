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
            return date.toLocaleDateString('en-US', { month: 'long' });
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
    const now = new Date(); 

    if (groupBy === 'day') {
      for (let i = -4; i <= 0; i++) {
        const date = new Date(now);
        date.setDate(now.getDate() + i);
        const key = date.toISOString().split('T')[0]; 
        categories.push(key);
        data.push(taskCounts[key] || 0);
      }
    } else if (groupBy === 'month') {
      for (let i = -4; i <= 0; i++) {
        const date = new Date(now.getFullYear(), now.getMonth() + i, 1);
        const key = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`;
        categories.push(key);
        data.push(taskCounts[key] || 0);
      }
    } else {
      for (let i = -4; i <= 0; i++) {
        const year = (now.getFullYear() + i).toString(); 
        categories.push(year);
        data.push(taskCounts[year] || 0);
      }
    }

    return { categories, data };
  }

  private generateEmptyCategories(): string[] {
    const categories: string[] = [];
    const now = new Date(); 

    if (this.selectedFilter === 'daily') {
      for (let i = -4; i <= 0; i++) {
        const date = new Date(now);
        date.setDate(now.getDate() + i);
        categories.push(date.toISOString().split('T')[0]); 
      }
    } else if (this.selectedFilter === 'monthly') {
      for (let i = -4; i <= 0; i++) {
        const date = new Date(now.getFullYear(), now.getMonth() + i, 1);
        categories.push(`${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`); 
      }
    } else {
      for (let i = -4; i <= 0; i++) {
        categories.push((now.getFullYear() + i).toString()); 
      }
    }
    return categories;
  }
}