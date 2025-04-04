import { NgClass, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterOutlet } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';
import { ButtonComponent } from 'src/app/shared/components/button/button.component';
import { DataService } from 'src/services/dataStorage';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-review',
  standalone: true,
  imports: [ButtonComponent, RouterOutlet, ReactiveFormsModule, NgIf, NgClass],
  templateUrl: './review.component.html',
  styleUrl: './review.component.css',
})
export class ReviewComponent {
  form!: FormGroup;
  submitted = false;
  imagePreview: File | null = null;
  duplicateEmailError: any = null;
  success_message: any = null;
  userId: Number | null = null;
  imageUrl: string | null = null;
  userData: any = null;
  first_name: string = '';
  profileImage: string | null = null;
  documentUrl: string | null = null; // New property to store the document URL
  documentName: string | null = null; // New property to store the document name

  constructor(
    private _formBuilder: FormBuilder,
    private userAccountService: UserAccountService,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: DataService,
  ) {}

  ngOnInit(): void {
    this.formValidation();
    this.userId = this.dataService.getUserID();
    if (this.userId === 0) {
      this.router.navigate(['user-management']);
    } else if (this.userId) {
      this.loadUserData();
      console.log('User ID being reviewed:', this.userId);
    }
  }

  formValidation(): void {
    this.form = this._formBuilder.group({
      firstName: ['', Validators.required],
      middleName: [''],
      lastName: ['', Validators.required],
      status: ['', Validators.required],
      userRole: ['', Validators.required],
      email: ['', Validators.required],
      bday: ['', Validators.required],
    });
  }

  loadUserData(): void {
    const userId = Number(this.userId);

    this.userAccountService.getUserById(userId).subscribe({
      next: (response: any) => {
        console.log('User data response:', response);
        this.userData = response.user;
        this.form.patchValue({
          firstName: response.user.first_name,
          middleName: response.user.middle_name,
          lastName: response.user.last_name,
          bday: response.user.birthdate,
          userRole: response.user.user_role,
          email: response.user.email,
          status: response.user.acc_status,
        });
        console.log('Form value after patching:', this.form.value);
        this.profileImage = response.user.image_link;

        // Fetch the documents for the user
        this.userAccountService.getUserDocuments(userId).subscribe({
          next: (docResponse: any) => {
            console.log('Raw response from getUserDocuments:', docResponse);

            let documents: { url: string, name: string }[] = [];

            // Check for documents directly in the response, accounting for the 'user' wrapper
            if (docResponse.user?.client_documents?.length > 0) {
              console.log('Processing Client documents:', docResponse.user.client_documents);
              documents = docResponse.user.client_documents.map((doc: any) => ({
                url: doc.document_url,
                name: 'Client_Document'
              }));
            }
            if (docResponse.user?.tasker?.length > 0) {
              console.log('Processing Tasker documents:', docResponse.user.tasker);
              const taskerDocs = docResponse.user.tasker[0]?.tasker_documents || [];
              const taskerDocuments = taskerDocs
                .filter((doc: any) => doc.tesda_document_link)
                .map((doc: any) => ({
                  url: doc.tesda_document_link,
                  name: 'TESDA_Document'
                }));
              documents = [...documents, ...taskerDocuments];
            }

            console.log('Final documents array:', documents);

            // If documents are found, set the first document's URL and name
            if (documents.length > 0) {
              this.documentUrl = documents[0].url;
              this.documentName = this.documentUrl.split('/').pop() || documents[0].name;
              console.log('Document URL set:', this.documentUrl);
              console.log('Document Name set:', this.documentName);
            } else {
              this.documentUrl = null;
              this.documentName = null;
              console.log('No documents found for this user.');
            }
          },
          error: (err) => {
            console.error('Error fetching documents:', err);
            this.documentUrl = null;
            this.documentName = null;
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'Failed to fetch documents. Please try again.',
            });
          }
        });
      },
      error: (error: any) => {
        console.error('Error fetching user data:', error);
      },
    });
  }

  onFileChange(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const file = input.files[0];
      this.imagePreview = file;

      const reader = new FileReader();
      reader.onload = () => {
        this.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  get f() {
    return this.form.controls;
  }

  onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      Swal.fire({
        icon: 'error',
        title: 'Validation Error',
        text: 'Please check the form for errors!',
      });
      return;
    }

    const userId = Number(this.userId);
    const email = this.form.value.email;
    this.updateUserAccount(userId);
  }

  updateUserAccount(userId: number): void {
    const formData = new FormData();
    formData.append('first_name', this.form.value.firstName);
    formData.append('middle_name', this.form.value.middleName);
    formData.append('last_name', this.form.value.lastName);
    formData.append('birthday', this.form.value.bday);
    formData.append('email', this.form.value.email);
    formData.append('acc_status', this.form.value.status);
    formData.append('user_role', this.form.value.userRole);

    if (this.imagePreview) {
      formData.append('image', this.imagePreview, this.imagePreview.name);
    }

    this.userAccountService.updateUserAccount(userId, formData).subscribe(
      (response) => {
        Swal.fire({
          icon: 'success',
          title: 'Success',
          text: 'User updated successfully!',
        }).then(() => {
          this.router.navigate(['user-management']);
        });
      },
      (error) => {
        Swal.fire({
          icon: 'error',
          title: 'Update Failed',
          text: error.error?.error,
        });
      },
    );
  }

  navigateToUsermanagement(): void {
    this.router.navigate(['user-management']);
  }
}