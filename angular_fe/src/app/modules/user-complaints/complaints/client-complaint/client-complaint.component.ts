import { CommonModule } from '@angular/common';
import { Component, AfterViewInit, ElementRef, ViewChild, ChangeDetectorRef, HostListener } from '@angular/core';
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

  currentIndex = 0;
  totalCards = 0;
  autoSwipeInterval: any;
  reports: any[] = [];

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
      const cards = this.clientSwiperWrapper.nativeElement.querySelectorAll('.client-swiper-card');
      this.totalCards = cards.length;
      this.updateSwiper();
      this.startAutoSwipe();

      this.clientSwiperWrapper.nativeElement.addEventListener('mouseenter', () => this.stopAutoSwipe());
      this.clientSwiperWrapper.nativeElement.addEventListener('mouseleave', () => this.startAutoSwipe());
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

  nextSlide() {
    this.currentIndex++;
    if (this.currentIndex >= this.totalCards) {
      this.currentIndex = 0;
    }
    this.updateSwiper();
  }

  startAutoSwipe() {
    this.autoSwipeInterval = setInterval(() => this.nextSlide(), 5000);
  }

  stopAutoSwipe() {
    clearInterval(this.autoSwipeInterval);
  }

  ngOnDestroy() {
    this.stopAutoSwipe();
  }
}