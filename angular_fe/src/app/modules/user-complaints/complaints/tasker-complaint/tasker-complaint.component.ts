import { CommonModule } from '@angular/common';
import { Component, AfterViewInit, ElementRef, ViewChild, ChangeDetectorRef, HostListener, Output, EventEmitter } from '@angular/core';
import { ReportService } from 'src/app/services/report.service';

@Component({
  selector: 'app-tasker-complaint',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './tasker-complaint.component.html',
  styleUrls: ['./tasker-complaint.component.css']
})
export class TaskerComplaintComponent implements AfterViewInit {
  @ViewChild('taskerSwiperWrapper') taskerSwiperWrapper!: ElementRef;

  currentIndex = 0;
  totalCards = 0;
  autoSwipeInterval: any;
  reports: any[] = [];

  // Added to emit the report ID to the parent component
  @Output() reportSelected = new EventEmitter<number>();

  constructor(
    private cdr: ChangeDetectorRef,
    private reportService: ReportService
  ) {}

  ngOnInit() {
    this.reportService.getReport().subscribe({
      next: (response) => {
        if (response.success) {
          this.reports = response.reports.filter((report: any) => report.reporter.user_role === 'Tasker');
          this.cdr.detectChanges();
          this.setupSwiper();
        } else {
          console.error('Failed to fetch reports: ', response.message); 
        }
      },
      error: (error) => {
        console.error('Error fetching reports: ', error);
      } 
    });
  }

  ngAfterViewInit() {
  }

  setupSwiper() {
    setTimeout(() => {
      const cards = this.taskerSwiperWrapper.nativeElement.querySelectorAll('.tasker-swiper-card');
      this.totalCards = cards.length;
      this.updateSwiper();
      this.startAutoSwipe();

      this.taskerSwiperWrapper.nativeElement.addEventListener('mouseenter', () => this.stopAutoSwipe());
      this.taskerSwiperWrapper.nativeElement.addEventListener('mouseleave', () => this.startAutoSwipe());
    });
  }

  @HostListener('window:resize', ['$event'])
  onResize(event: Event) {
    this.updateSwiper();
  }

  updateSwiper() {
    if (this.taskerSwiperWrapper && this.taskerSwiperWrapper.nativeElement) {
      const cardWidth = this.taskerSwiperWrapper.nativeElement.querySelector('.tasker-swiper-card')?.offsetWidth || 0;
   
      this.taskerSwiperWrapper.nativeElement.style.transition = 'none';
      this.taskerSwiperWrapper.nativeElement.offsetHeight;
      this.taskerSwiperWrapper.nativeElement.style.transition = 'transform 100ms ease-in-out';
      this.taskerSwiperWrapper.nativeElement.style.transform = `translateX(-${this.currentIndex * cardWidth}px)`;
      this.cdr.detectChanges();
    }
  }

  nextSlide() {
    this.currentIndex++;
    if (this.currentIndex >= this.totalCards) {
      this.currentIndex = 0;
    }
    this.updateSwiper();
  }

  startAutoSwipe() {
    this.autoSwipeInterval = setInterval(() => this.nextSlide(), 3000);
  }

  stopAutoSwipe() {
    clearInterval(this.autoSwipeInterval);
  }

  ngOnDestroy() {
    this.stopAutoSwipe();
  }

  selectAction(reportId: number) {
    this.reportSelected.emit(reportId);
  }
}