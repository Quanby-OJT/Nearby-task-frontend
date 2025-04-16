import { Component, OnInit } from '@angular/core';
// import { ActivatedRoute } from '@angular/router'; // Removed ActivatedRoute
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-my-profile',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './my-profile.component.html',
  styleUrl: './my-profile.component.css'
})
export class MyProfileComponent /*implements OnInit*/ { // Removed OnInit
  // userId: string = ''; // Removed userId

  constructor(/*private route: ActivatedRoute*/) {} // Removed ActivatedRoute injection

  /* ngOnInit() { // Removed ngOnInit logic
    this.route.params.subscribe(params => {
      this.userId = params['id'];
      console.log('User ID:', this.userId);
    });
  }*/
}
