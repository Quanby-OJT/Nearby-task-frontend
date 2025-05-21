import { NgClass, NgIf } from '@angular/common';
import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterOutlet } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';
import { ButtonComponent } from 'src/app/shared/components/button/button.component';
import { DataService } from 'src/services/dataStorage';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import Swal from 'sweetalert2';
import { HttpClient, HttpHeaders } from '@angular/common/http';

@Component({
  selector: 'app-review',
  standalone: true,
  imports: [
    ButtonComponent,
    RouterOutlet,
    ReactiveFormsModule,
    NgIf,
    NgClass
  ],
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
  documentUrl: string | null = null;
  documentName: string | null = null;
  isImage: boolean = false;

  constructor(
    private _formBuilder: FormBuilder,
    private userAccountService: UserAccountService,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: DataService,
    private sessionStorage: SessionLocalStorage,
    private http: HttpClient
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

        this.userAccountService.getUserDocuments(userId).subscribe({
          next: (docResponse: any) => {
            console.log('Raw response from getUserDocuments:', docResponse);

            let documents: { url: string, name: string }[] = [];

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

            if (documents.length > 0) {
              this.documentUrl = documents[0].url;
              this.documentName = this.documentUrl.split('/').pop() || documents[0].name;
              console.log('Document URL set:', this.documentUrl);
              console.log('Document Name set:', this.documentName);

              // Determine if the file is an image based on its extension
              const extension = this.documentUrl.split('.').pop()?.toLowerCase();
              this.isImage = ['jpg', 'jpeg', 'png', 'gif'].includes(extension || '');
              console.log('Is file an image?', this.isImage);
            } else {
              this.documentUrl = null;
              this.documentName = null;
              this.isImage = false;
              console.log('No documents found for this user.');
            }
          },
          error: (err) => {
            console.error('Error fetching documents:', err);
            this.documentUrl = null;
            this.documentName = null;
            this.isImage = false;
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

  previewDocument(): void {
    if (!this.documentUrl) {
      console.error('No document URL available to preview.');
      Swal.fire({
        icon: 'warning',
        title: 'No Document',
        text: 'There is no document available to preview for this user.',
      });
      return;
    }

    const urlParts = this.documentUrl.split('/storage/v1/object/public/crud_bucket/');
    if (urlParts.length < 2) {
      console.error('Could not extract file path from document URL:', this.documentUrl);
      Swal.fire({
        icon: 'error',
        title: 'Preview Failed',
        text: 'Invalid document URL format.',
      });
      return;
    }

    const filePath = urlParts[1];
    console.log('Extracted file path:', filePath);

    // Construct the URL to fetch the PDF
    const url = `https://localhost:5000/connect/viewDocument/${encodeURIComponent(filePath)}`;
    const token = this.sessionStorage.getSessionToken();
    if (!token) {
      console.error('No session token found. Please log in.');
      Swal.fire({
        icon: 'error',
        title: 'Authentication Error',
        text: 'Please log in to view the document.',
      });
      this.router.navigate(['login']);
      return;
    }

    // Open the URL in a new tab
    const newWindow = window.open(url, '_blank');
    if (!newWindow) {
      Swal.fire({
        icon: 'error',
        title: 'Preview Failed',
        text: 'Unable to open the document. Please allow pop-ups for this site.',
      });
    }
  }

  previewImage(): void {
    if (!this.documentUrl) {
      console.error('No image URL available to preview.');
      Swal.fire({
        icon: 'warning',
        title: 'No Image',
        text: 'There is no image available to preview for this user.',
      });
      return;
    }

    // Directly open the image URL in a new tab
    const newWindow = window.open(this.documentUrl, '_blank');
    if (!newWindow) {
      Swal.fire({
        icon: 'error',
        title: 'Preview Failed',
        text: 'Unable to open the image. Please allow pop-ups for this site.',
      });
    }
  }
}
