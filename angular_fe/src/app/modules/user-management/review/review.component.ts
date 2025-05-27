import { NgClass, NgIf } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { ActivatedRoute, Router, RouterOutlet } from '@angular/router';
import { UserAccountService } from 'src/app/services/userAccount';
import { ButtonComponent } from 'src/app/shared/components/button/button.component';
import { DataService } from 'src/services/dataStorage';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import Swal from 'sweetalert2';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';

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
  Form!: FormGroup;
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
  faceImage: string | null = null;
  isFaceImage: boolean = false;
  idImage: string | null = null;
  isIdImage: boolean = false;
  actionByName: string = '';

  constructor(
    private _formBuilder: FormBuilder,
    private userAccountService: UserAccountService,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: DataService,
    private sessionStorage: SessionLocalStorage,
    private http: HttpClient,
    private cdRef: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.formValidation();
    this.userId = this.dataService.getUserID();
    if (this.userId === 0) {
      this.router.navigate(['user-management']);
    } else if (this.userId) {
      this.loadUserData();
      this.loadActionByName();
      console.log('User ID being reviewed:', this.userId);
    }
  }

  loadActionByName(): void {
    const actionById = localStorage.getItem('user_id');
    if (actionById) {
      this.userAccountService.getUserById(Number(actionById)).subscribe({
        next: (response: any) => {
          const user = response.user || response;
          this.actionByName = `${user.first_name || ''} ${user.middle_name || ''} ${user.last_name || ''}`.trim();
          this.cdRef.detectChanges();
        },
        error: (error: any) => {
          console.error('Error fetching action_by user data:', error);
          this.actionByName = 'Unknown User';
          this.cdRef.detectChanges();
        },
      });
    }
  }

  formValidation(): void {
    this.Form = this._formBuilder.group({
      firstName: ['', Validators.required],
      middleName: [''],
      lastName: ['', Validators.required],
      status: ['', Validators.required],
      userRole: ['', Validators.required],
      email: ['', Validators.required],
      bday: ['', Validators.required],
      age: [{ value: '', disabled: true }]
    });
  }

  calculateAge(birthdate: string): number {
    if (!birthdate) return 0;
    const today = new Date('2025-05-15');
    const birthDate = new Date(birthdate);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  }

  loadUserData(): void {
    const userId = Number(this.userId);

    this.userAccountService.getUserById(userId).subscribe({
      next: (response: any) => {
        console.log('User data response:', response);
        this.userData = response.user;
        const age = this.calculateAge(response.user.birthdate);
        this.Form.patchValue({
          firstName: response.user.first_name,
          middleName: response.user.middle_name,
          lastName: response.user.last_name,
          bday: response.user.birthdate,
          userRole: response.user.user_role,
          email: response.user.email,
          status: response.user.acc_status,
          age: age
        });
        console.log('Form value after patching:', this.Form.value);
        this.profileImage = response.user.image_link; // Set profileImage from image_link

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
            if (docResponse.user?.user_documents?.length > 0) {
              console.log('Processing User documents:', docResponse.user.user_documents);
              documents = [...documents, ...docResponse.user.user_documents.map((doc: any) => ({
                url: doc.user_document_link,
                name: doc.doc_name || 'User_Document'
              }))];
            }

            if (docResponse.user?.user_id?.length > 0 && docResponse.user.user_id[0]?.id_image) {
              console.log('Processing ID image:', docResponse.user.user_id[0].id_image);
              this.idImage = docResponse.user.user_id[0].id_image; // Set idImage directly
              const idExtension = this.idImage?.split('.').pop()?.toLowerCase() || '';
              this.isIdImage = ['jpg', 'jpeg', 'png', 'gif'].includes(idExtension);
              console.log('Is id_image an image?', this.isIdImage);
              documents.push({
                url: docResponse.user.user_id[0].id_image,
                name: 'ID_Image'
              });
            } else {
              this.idImage = null;
              this.isIdImage = false;
              console.log('No id_image found for this user.');
            }
            // Check for face_image from user_face_identity table (now an array)
            if (docResponse.user?.user_face_identity?.length > 0 && docResponse.user.user_face_identity[0]?.face_image) {
              console.log('Processing Selfie Image:', docResponse.user.user_face_identity[0].face_image);
              this.faceImage = docResponse.user.user_face_identity[0].face_image;
              // Safely handle null or undefined faceImage
              const faceExtension = this.faceImage?.split('.').pop()?.toLowerCase() || '';
              this.isFaceImage = ['jpg', 'jpeg', 'png', 'gif'].includes(faceExtension);
              console.log('Is face_image an image?', this.isFaceImage);
            } else {
              this.faceImage = null;
              this.isFaceImage = false;
              console.log('No face_image found for this user.');
            }

            console.log('Final documents array:', documents);

            if (documents.length > 0) {
              // Prioritize user_document_link (PDF) for display if it exists
              const userDoc = documents.find(doc => doc.name === 'User_Document' && doc.url.endsWith('.pdf'));
              if (userDoc) {
                this.documentUrl = userDoc.url;
                this.documentName = this.documentUrl.split('/').pop() || userDoc.name;
              } else {
                // Fallback to any other document if no PDF user_document_link is found
                this.documentUrl = documents[0].url;
                this.documentName = this.documentUrl.split('/').pop() || documents[0].name;
              }
              console.log('Document URL set:', this.documentUrl);
              console.log('Document Name set:', this.documentName);

              // Determine if the file is an image based on its extension
              const extension = this.documentUrl.split('.').pop()?.toLowerCase();
              this.isImage = ['jpg', 'jpeg', 'png', 'gif'].includes(extension || '');
              console.log('Is file an image?', this.isImage);

              // Set the imageUrl for display in the template
              if (this.isImage) {
                this.imageUrl = this.documentUrl;
              }
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
            this.faceImage = null; // Ensure faceImage is reset on error
            this.isFaceImage = false;
            this.idImage = null;   // Reset idImage on error
            this.isIdImage = false; // Reset isIdImage on error
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
    return this.Form.controls;
  }

  onSubmit() {
    this.submitted = true;

    if (this.Form.invalid) {
      Swal.fire({
        icon: 'error',
        title: 'Validation Error',
        text: 'Please check the form for errors!',
      });
      return;
    }
    // Submission is now handled via updateStatusWithReason
  }

  async updateStatusWithReason() {
    this.submitted = true;

    if (this.Form.invalid) {
      Swal.fire({
        icon: 'error',
        title: 'Validation Error',
        text: 'Please select a valid user role and status!',
      });
      return;
    }

    const { value: reason } = await Swal.fire({
      title: 'Update User Status',
      html: `
        <label for="reason-input" class="block text-sm font-medium text-gray-700 mb-2">Reason for this action</label>
        <input id="reason-input" class="swal2-input" placeholder="Enter reason" />
      `,
      showCancelButton: true,
      confirmButtonText: 'Confirm',
      cancelButtonText: 'Cancel',
      preConfirm: () => {
        const reasonInput = (document.getElementById('reason-input') as HTMLInputElement).value;
        if (!reasonInput) {
          Swal.showValidationMessage('Please provide a reason for this action');
        }
        return reasonInput;
      },
      willOpen: () => {
        const confirmButton = Swal.getConfirmButton();
        const reasonInput = document.getElementById('reason-input') as HTMLInputElement;

        if (confirmButton) {
          confirmButton.disabled = true;
        }

        reasonInput.addEventListener('input', () => {
          if (confirmButton) {
            confirmButton.disabled = !reasonInput.value.trim();
          }
        });
      }
    });

    if (reason) {
      const userId = Number(this.userId);
      this.updateUserAccount(userId, reason);
    }
  }

  updateUserAccount(userId: number, reason: string): void {
    const userData = {
      first_name: this.Form.value.firstName,
      middle_name: this.Form.value.middleName,
      last_name: this.Form.value.lastName,
      birthday: this.Form.value.bday,
      email: this.Form.value.email,
      acc_status: this.Form.value.status,
      user_role: this.Form.value.userRole,
      action_by: localStorage.getItem('user_id') || '0'
    };

    this.userAccountService.updateUserAccountWithReason(userId, userData, reason).subscribe(
      (response) => {
        Swal.fire({
          icon: 'success',
          title: 'Success',
          text: 'User status updated successfully!',
        }).then(() => {
          this.router.navigate(['user-management']);
        });
      },
      (error) => {
        Swal.fire({
          icon: 'error',
          title: 'Update Failed',
          text: error.error?.error || 'An error occurred while updating the user status.',
        });
      }
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

    const url = `${this.userAccountService['apiUrl']}/viewDocument/${encodeURIComponent(filePath)}`;
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

    this.http.get(url, {
      headers: new HttpHeaders({
        'Authorization': `Bearer ${token}`
      }),
      responseType: 'blob',
      withCredentials: true
    }).subscribe({
      next: (blob) => {
        console.log('Document fetched successfully, creating blob URL');
        const blobUrl = window.URL.createObjectURL(blob);
        const newWindow = window.open(blobUrl, '_blank');
        if (!newWindow) {
          Swal.fire({
            icon: 'error',
            title: 'Preview Failed',
            text: 'Unable to open the document. Please allow pop-ups for this site.',
          });
        }
      },
      error: (err) => {
        console.error('Error fetching document:', err);
        let message = 'Failed to fetch the document. Please try again.';
        if (err.status === 401) {
          message = 'Unauthorized. Please log in again.';
          this.router.navigate(['login']);
        } else if (err.status === 404) {
          message = 'Document not found.';
        } else if (err.status >= 500) {
          message = `Server error (status: ${err.status}). Contact support with this error code.`;
        }
        Swal.fire({
          icon: 'error',
          title: 'Preview Failed',
          text: message,
        });
      }
    });
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

    const newWindow = window.open(this.documentUrl, '_blank');
    if (!newWindow) {
      Swal.fire({
        icon: 'error',
        title: 'Preview Failed',
        text: 'Unable to open the image. Please allow pop-ups for this site.',
      });
    }
  }

  compareImages(): void {
    let idImageHtml = '';
    if (this.idImage && this.isIdImage) {
      idImageHtml = `
        <div style="position: relative; width: 200px; height: 200px;">
          <div class="image-spinner" style="display: flex; justify-content: center; align-items: center; width: 200px; height: 200px; background: #f0f0f0;">
            <div style="border: 4px solid #f3f3f3; border-top: 4px solid #5F50E7; border-radius: 50%; width: 30px; height: 30px; animation: spin 1s linear infinite;"></div>
          </div>
          <a href="${this.idImage}" target="_blank">
            <img src="${this.idImage}" alt="ID Image" style="width: 200px; height: 200px; object-fit: cover; display: none;" onload="this.style.display='block'; this.parentNode.parentNode.querySelector('.image-spinner').style.display='none';" onerror="this.parentNode.parentNode.innerHTML='<div style=\\'width: 200px; height: 200px; background: #f0f0f0; display: flex; justify-content: center; align-items: center; color: #666; font-size: 14px; text-align: center;\\' >No ID Image Available</div>';"/>
          </a>
        </div>
      `;
    } else {
      idImageHtml = '<div style="width: 200px; height: 200px; background: #f0f0f0; display: flex; justify-content: center; align-items: center; color: #666; font-size: 14px; text-align: center;">No ID Image Available</div>';
    }

    let faceImageHtml = '';
    if (this.faceImage && this.isFaceImage) {
      faceImageHtml = `
        <div style="position: relative; width: 200px; height: 200px;">
          <div class="image-spinner" style="display: flex; justify-content: center; align-items: center; width: 200px; height: 200px; background: #f0f0f0;">
            <div style="border: 4px solid #f3f3f3; border-top: 4px solid #5F50E7; border-radius: 50%; width: 30px; height: 30px; animation: spin 1s linear infinite;"></div>
          </div>
          <a href="${this.faceImage}" target="_blank">
            <img src="${this.faceImage}" alt="Selfie Image" style="width: 200px; height: 200px; object-fit: cover; display: none;" onload="this.style.display='block'; this.parentNode.parentNode.querySelector('.image-spinner').style.display='none';" onerror="this.parentNode.parentNode.innerHTML='<div style=\\'width: 200px; height: 200px; background: #f0f0f0; display: flex; justify-content: center; align-items: center; color: #666; font-size: 14px; text-align: center;\\' >No Selfie Image Available</div>';"/>
          </a>
        </div>
      `;
    } else {
      faceImageHtml = '<div style="width: 200px; height: 200px; background: #f0f0f0; display: flex; justify-content: center; align-items: center; color: #666; font-size: 14px; text-align: center;">No Selfie Image Available</div>';
    }

    const htmlContent = `
      <style>
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      </style>
      <div style="max-height: 400px; overflow-y: auto; padding-right: 10px; display: flex; justify-content: center; gap: 20px;">
        <div style="text-align: center;">
          <div style="margin-bottom: 10px; font-weight: bold;">ID Image</div>
          ${idImageHtml}
        </div>
        <div style="text-align: center;">
          <div style="margin-bottom: 10px; font-weight: bold;">Selfie Image</div>
          ${faceImageHtml}
        </div>
      </div>
    `;

    Swal.fire({
      title: 'Compare ID Photo and Selfie',
      html: htmlContent,
      width: '800px',
      showCloseButton: false,
      showConfirmButton: true,
      confirmButtonText: 'Close',
      confirmButtonColor: '#FF0000',
      customClass: {
        htmlContainer: 'text-center',
        actions: 'swal2-actions-right'
      },
      didOpen: () => {
        const actions = document.querySelector('.swal2-actions');
        if (actions) {
          actions.setAttribute('style', 'display: flex; justify-content: flex-end; width: 90%;');
        }
      }
    });
  }
}