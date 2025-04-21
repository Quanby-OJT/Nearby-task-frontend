import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FeedbackService } from 'src/app/services/feedback.service';

@Component({
  selector: 'app-feedback',
  imports: [CommonModule],
  templateUrl: './feedback.component.html',
  styleUrl: './feedback.component.css'
})
export class FeedbackComponent {
  feedbacks: any[] = [];

  constructor(private feedbackService: FeedbackService) {}

  ngOnInit(): void {
    this.feedbackService.getFeedback().subscribe(
      (response: any) => {
        console.log('Received feedback data:', response);
        this.feedbacks = response.feedbacks || [];
      },
      (error) => {
        console.error('Error fetching feedbacks', error);
      }
    );
  }
}
