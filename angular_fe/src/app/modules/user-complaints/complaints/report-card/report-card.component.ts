import { Component, AfterViewInit, ElementRef, ViewChild, ChangeDetectorRef, HostListener, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReportService } from 'src/app/services/report.service';

@Component({
  selector: 'app-report-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './report-card.component.html',
  styleUrls: ['./report-card.component.css']
})
export class ReportCardComponent implements AfterViewInit {
  @ViewChild('carouselTrack') carouselTrack!: ElementRef;
  @Output() reportSelected = new EventEmitter<number>();

  currentIndex: number = 0;
  totalCards = 0;
  reports: any[] = [];
  autoSwipeInterval: any;
  cardWidth: number = 330; // 300px card width + 30px gap
  readonly SWIPE_INTERVAL = 4000; // 4 seconds in milliseconds

  constructor(
    private cdr: ChangeDetectorRef,
    private reportService: ReportService
  ) {}

  ngOnInit() {
    this.reportService.getReport().subscribe({
      next: (response) => {
        if (response.success) {
          this.reports = response.reports;
          this.cdr.detectChanges();
          this.setupSwiper();
        } else {
          console.error('Failed to fetch reports: ', response.message);
        }
      },
      error: (err) => {
        console.error('Error fetching reports:', err);
      }
    });
  }

  ngAfterViewInit() {
  }

  setupSwiper() {
    setTimeout(() => {
      const cards = this.carouselTrack.nativeElement.querySelectorAll('.card');
      this.totalCards = cards.length;
      this.updateSwiper();
      if (this.totalCards > 0) {
        this.startAutoSwipe();
      }
    }, 0);
  }

  @HostListener('window:resize', ['$event'])
  onResize(event: Event) {
    this.updateSwiper();
  }

  updateSwiper() {
    if (this.carouselTrack && this.carouselTrack.nativeElement) {
      this.carouselTrack.nativeElement.style.transition = 'none';
      this.carouselTrack.nativeElement.offsetHeight;
      this.carouselTrack.nativeElement.style.transition = 'transform 1200ms ease-in-out';
      this.carouselTrack.nativeElement.style.transform = `translateX(-${this.currentIndex * this.cardWidth}px)`;
      this.cdr.detectChanges();
    }
  }

  startAutoSwipe() {
    this.stopAutoSwipe(); // Clear any existing interval
    this.autoSwipeInterval = setInterval(() => {
      this.currentIndex++;
      if (this.currentIndex >= this.totalCards) {
        this.currentIndex = 0;
      }
      this.updateSwiper();
    }, this.SWIPE_INTERVAL);
  }

  stopAutoSwipe() {
    if (this.autoSwipeInterval) {
      clearInterval(this.autoSwipeInterval);
      this.autoSwipeInterval = null;
    }
  }

  swipePrev() {
    this.currentIndex--;
    if (this.currentIndex < 0) {
      this.currentIndex = this.totalCards - 1;
    }
    this.updateSwiper();
    this.startAutoSwipe(); // Reset the timer
  }

  swipeNext() {
    this.currentIndex++;
    if (this.currentIndex >= this.totalCards) {
      this.currentIndex = 0;
    }
    this.updateSwiper();
    this.startAutoSwipe(); // Reset the timer
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
