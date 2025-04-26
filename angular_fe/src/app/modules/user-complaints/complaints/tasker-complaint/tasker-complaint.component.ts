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

  currentIndex: number = 0; // Manage own index
  totalCards = 0;
  reports: any[] = [];
  autoSwipeInterval: any;

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
      if (this.totalCards > 0) {
        this.startAutoSwipe();
      }
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

  startAutoSwipe() {
    this.autoSwipeInterval = setInterval(() => {
      this.currentIndex++;
      if (this.currentIndex >= this.totalCards) {
        this.currentIndex = 0;
      }
      this.updateSwiper();
    }, 3000);
  }

  stopAutoSwipe() {
    clearInterval(this.autoSwipeInterval);
  }

  swipePrev() {
    this.currentIndex--;
    if (this.currentIndex < 0) {
      this.currentIndex = this.totalCards - 1;
    }
    this.updateSwiper();
  }

  swipeNext() {
    this.currentIndex++;
    if (this.currentIndex >= this.totalCards) {
      this.currentIndex = 0;
    }
    this.updateSwiper();
  }

  ngOnDestroy() {
    this.stopAutoSwipe();
  }

  selectAction(reportId: number) {
    this.reportSelected.emit(reportId);
  }

  onSwipePrev() {
    this.swipePrev();
  }

  onSwipeNext() {
    this.swipeNext();
  }
}