import { CommonModule } from '@angular/common';
import { Component, AfterViewInit, ElementRef, ViewChild, ChangeDetectorRef, HostListener } from '@angular/core';
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

  constructor(
    private cdr: ChangeDetectorRef,
    private reportService: ReportService
  ) {}

ngOnInit(){
  this.reportService.getReport().subscribe({
    next: (response) => {
      if (response.success) {
        this.reports = response.reports;
        this.cdr.detectChanges();
        this.setupSwiper();
      } else {
        console.error('Failed to getch reports: ', response.message);
      }
    },
    error: (error) => {
      console.error('Error fetching reports: ', error);
    } 
  })
}


  ngAfterViewInit() {
  }

setupSwiper() {
  setTimeout(() =>{
    const cards = this.taskerSwiperWrapper.nativeElement.querySelectorAll('.tasker-swiper-card');
    this.totalCards = cards.length;
    this.updateSwiper();
    this.startAutoSwipe();

    this.taskerSwiperWrapper.nativeElement.addEventListener('mouseenter', () => this.stopAutoSwipe());
    this.taskerSwiperWrapper.nativeElement.addEventListener('mouseleave', () => this.startAutoSwipe());

  })
}

  @HostListener('window:resize', ['$event'])
  onResize(event: Event) {
    this.updateSwiper();
  }
//tasker-swiper-card
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
    this.autoSwipeInterval = setInterval(() => this.nextSlide(), 5000);
  }

  stopAutoSwipe() {
    clearInterval(this.autoSwipeInterval);
  }

  ngOnDestroy() {
    this.stopAutoSwipe();
  }
}