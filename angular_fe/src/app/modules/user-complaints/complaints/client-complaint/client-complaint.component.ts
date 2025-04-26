import { CommonModule } from '@angular/common';
import { Component, AfterViewInit, ElementRef, ViewChild, ChangeDetectorRef, HostListener, Output, EventEmitter } from '@angular/core';
import { ReportService } from 'src/app/services/report.service';

@Component({
  selector: 'app-client-complaint',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './client-complaint.component.html',
  styleUrls: ['./client-complaint.component.css']
})
export class ClientComplaintComponent implements AfterViewInit {
  @ViewChild('clientSwiperWrapper') clientSwiperWrapper!: ElementRef;

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
          this.reports = response.reports.filter((report: any) => report.reporter.user_role === 'Client');
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
      const cards = this.clientSwiperWrapper.nativeElement.querySelectorAll('.client-swiper-card');
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
    if (this.clientSwiperWrapper && this.clientSwiperWrapper.nativeElement) {
      const cardWidth = this.clientSwiperWrapper.nativeElement.querySelector('.client-swiper-card')?.offsetWidth || 0;
      this.clientSwiperWrapper.nativeElement.style.transition = 'none';
      this.clientSwiperWrapper.nativeElement.offsetHeight; 
      this.clientSwiperWrapper.nativeElement.style.transition = 'transform 100ms ease-in-out';
      this.clientSwiperWrapper.nativeElement.style.transform = `translateX(-${this.currentIndex * cardWidth}px)`;
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