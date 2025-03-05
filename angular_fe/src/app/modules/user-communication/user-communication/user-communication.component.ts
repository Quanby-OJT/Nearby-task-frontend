import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { DemoService } from 'src/app/services/demo.service';

@Component({
  selector: 'app-user-communication',
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './user-communication.component.html',
  styleUrl: './user-communication.component.css',
})
export class UserCommunicationComponent implements OnInit {
  users: any[] = [];
  userForm: FormGroup;
  selectedFile: File | null = null;

  constructor(private userService: DemoService, private fb: FormBuilder) {
    this.userForm = this.fb.group({
      first_name: [''],
      last_name: [''],
      email: [''],
      password: [''],
    });
  }

  ngOnInit(): void {
    this.getAllUsers();
  }

  onFileSelect(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];
    }
  }

  getAllUsers(): void {
    this.userService.getAllUsers().subscribe(
      (response) => {
        this.users = response.users;
      },
      (error) => {
        console.error('Error fetching users:', error);
      },
    );
  }

  addUser(): void {
    const formData = new FormData();
    formData.append('first_name', this.userForm.value.first_name);
    formData.append('last_name', this.userForm.value.last_name);
    formData.append('email', this.userForm.value.email);
    formData.append('password', this.userForm.value.password);
    if (this.selectedFile) {
      formData.append('image', this.selectedFile);
    }

    this.userService.insertUser(formData).subscribe(
      (response) => {
        console.log('User added successfully:', response);
        this.getAllUsers();
        this.userForm.reset();
      },
      (error) => {
        console.error('Error adding user:', error);
      },
    );
  }
}
