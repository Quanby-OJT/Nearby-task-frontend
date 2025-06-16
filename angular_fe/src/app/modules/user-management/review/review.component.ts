import { CommonModule, NgClass, NgIf } from '@angular/common';
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
    NgClass,
    CommonModule
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
  userDocuments: { url: string; name: string; type: string }[] = [];
  isImage: boolean = false;
  faceImage: string | null = null;
  isFaceImage: boolean = false;
  idImage: string | null = null;
  isIdImage: boolean = false;
  actionByName: string = '';
  userRole: string = '';

  constructor(
    private _formBuilder: FormBuilder,
    private userAccountService: UserAccountService,
    private router: Router,
    private route: ActivatedRoute,
    private dataService: DataService,
    private sessionStorage: SessionLocalStorage,
    private http: HttpClient,
    private cdRef: ChangeDetectorRef
  ) { }

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

    // Get current user's role
    const currentUserId = localStorage.getItem('user_id');
    if (currentUserId) {
      this.userAccountService.getUserById(Number(currentUserId)).subscribe({
        next: (response: any) => {
          const user = response.user || response;
          this.userRole = user.user_role || 'Unknown';
          this.cdRef.detectChanges();
        },
        error: (error: any) => {
          console.error('Error fetching current user role:', error);
          this.userRole = 'Unknown';
          this.cdRef.detectChanges();
        }
      });
    }
  }

  loadActionByName(): void {
    const actionById = localStorage.getItem('user_id');
    if (actionById) {
      this.userAccountService.getUserById(Number(actionById)).subscribe({
        next: (response: any) => {
          const user = response.user || response;
          this.actionByName = `${user.first_name || ''} ${user.middle_name || ''} ${user.last_name || ''}`.trim();
          this.userRole = user.user_role || 'Unknown';
          this.cdRef.detectChanges();
        },
        error: (error: any) => {
          console.error('Error fetching action_by user data:', error);
          this.actionByName = 'Unknown User';
          this.userRole = 'Unknown';
          this.cdRef.detectChanges();
        },
      });
    }
  }

  formValidation(): void {
    this.Form = this._formBuilder.group({
      firstName: [''],
      middleName: [''],
      lastName: [''],
      status: [''],
      userRole: [''],
      email: [''],
      bday: [''],
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
    console.log('Loading data for user ID:', userId);

    this.userAccountService.getUserById(userId).subscribe({
      next: (response: any) => {
        console.log('Raw Backend Response (ReviewComponent):', response);
        // Debugging: Log the keys available in the response object
        console.log('Response keys (ReviewComponent):', Object.keys(response));

        // Assuming the user data is nested under 'user' based on previous analysis
        this.userData = response.user;
        console.log('Processed User Data (ReviewComponent):', this.userData);

        if (this.userData) {
          // If there's an action_by, fetch that user's data to get their role
          if (this.userData.action_by) {
            this.userAccountService.getUserById(Number(this.userData.action_by)).subscribe({
              next: (actionByResponse: any) => {
                const actionByUser = actionByResponse.user || actionByResponse;
                this.userData.action_by_user = {
                  first_name: actionByUser.first_name,
                  middle_name: actionByUser.middle_name,
                  last_name: actionByUser.last_name,
                  user_role: actionByUser.user_role
                };
                this.cdRef.detectChanges();
              },
              error: (error: any) => {
                console.error('Error fetching action_by user data:', error);
              }
            });
          }

          const age = this.calculateAge(this.userData.birthdate);
          this.Form.patchValue({
            firstName: this.userData.first_name || '',
            middleName: this.userData.middle_name || '',
            lastName: this.userData.last_name || '',
            bday: this.userData.birthdate ? new Date(this.userData.birthdate).toISOString().split('T')[0] : '', // Format date for input
            userRole: this.userData.user_role || '',
            email: this.userData.email || '',
            status: this.userData.acc_status || this.userData.status || '',
            age: age
          });

          console.log('Form value after patching (ReviewComponent):', this.Form.value);
          this.profileImage = this.userData.image_link; // Set profileImage from image_link
          console.log('Profile Image URL:', this.profileImage);

          this.userAccountService.getUserDocuments(userId).subscribe({
            next: (docResponse: any) => {
              console.log('Raw response from getUserDocuments (ReviewComponent):', docResponse);

              // Process user documents with the new structure
              let userDocuments: { url: string, name: string, type: string }[] = [];

              // Process user_documents object (not an array)
              if (docResponse.user?.user?.user_documents && docResponse.user.user.user_documents.user_document_link) {
                userDocuments.push({
                  url: docResponse.user.user.user_documents.user_document_link,
                  name: 'User_Document',
                  type: docResponse.user.user.user_documents.document_type || 'No Type'
                });
              }

              // Process ID image
              if (docResponse.user?.user?.user_id?.id_image) {
                this.idImage = docResponse.user.user.user_id.id_image;
                const idExtension = this.idImage?.split('.').pop()?.toLowerCase() || '';
                this.isIdImage = ['jpg', 'jpeg', 'png', 'gif'].includes(idExtension);
                console.log('ID Image URL:', this.idImage, 'isIdImage:', this.isIdImage);
              } else {
                this.idImage = null;
                this.isIdImage = false;
                console.log('ID Image URL: null');
              }

              // Process Selfie image
              if (docResponse.user?.user?.user_face_identity?.face_image) {
                this.faceImage = docResponse.user.user.user_face_identity.face_image;
                const faceExtension = this.faceImage?.split('.').pop()?.toLowerCase() || '';
                this.isFaceImage = ['jpg', 'jpeg', 'png', 'gif'].includes(faceExtension);
                console.log('Face Image URL:', this.faceImage, 'isFaceImage:', this.isFaceImage);
              } else {
                this.faceImage = null;
                this.isFaceImage = false;
                console.log('Face Image URL: null');
              }

              // Store all user documents
              this.userDocuments = userDocuments;
              console.log('Stored user documents:', this.userDocuments);

              // Check if the first document is an image
              if (this.userDocuments.length > 0) {
                const firstDoc = this.userDocuments[0];
                const extension = firstDoc.url.split('.').pop()?.toLowerCase();
                this.isImage = ['jpg', 'jpeg', 'png', 'gif'].includes(extension || '');
                this.imageUrl = this.isImage ? firstDoc.url : null;
              } else {
                this.isImage = false;
                this.imageUrl = null;
              }

              this.cdRef.detectChanges();
            },
            error: (err) => {
              console.error('Error fetching documents (ReviewComponent):', err);
              this.userDocuments = [];
              this.faceImage = null;
              this.isFaceImage = false;
              this.idImage = null;
              this.isIdImage = false;
              Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Failed to fetch documents. Please try again.',
              });
              this.cdRef.detectChanges();
            }
          });
        } else {
          console.warn('No user data found in response (ReviewComponent)');
          Swal.fire({
            icon: 'warning',
            title: 'No Data',
            text: 'User data not found for this ID.',
          });
          this.cdRef.detectChanges();
        }
      },
      error: (error: any) => {
        console.error('Error fetching user data (ReviewComponent):', error);
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Failed to load user data: ' + (error.message || 'Unknown error'),
        });
        this.cdRef.detectChanges();
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

    // Check if current user is Moderator and prior action was by Admin
    if (this.userRole === 'Moderator' && this.userData?.action_by_user?.user_role === 'Admin') {
      await Swal.fire('Error', "You don't have authority to take action here since this action is made by an admin", 'error');
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

  previewDocument(documentUrl: string): void {
    if (!documentUrl) {
      console.error('No document URL available to preview.');
      Swal.fire({
        icon: 'warning',
        title: 'No Document',
        text: 'There is no document URL provided.',
      });
      return;
    }

    // Check if the document is an image. If so, use the previewImage logic.
    const extension = documentUrl.split('.').pop()?.toLowerCase();
    const isImageUrl = ['jpg', 'jpeg', 'png', 'gif', 'svg'].includes(extension || '');

    if (isImageUrl) {
      this.previewImage(documentUrl);
      return;
    }

    // Extract bucket name and file path from the Supabase public URL
    // Example: https://<project>.supabase.co/storage/v1/object/public/<bucket>/<filePath>
    const marker = '/storage/v1/object/public/';
    const markerIndex = documentUrl.indexOf(marker);
    if (markerIndex === -1) {
      Swal.fire({
        icon: 'error',
        title: 'Preview Failed',
        text: 'Invalid document URL format.',
      });
      return;
    }

    const afterMarker = documentUrl.substring(markerIndex + marker.length);
    const firstSlash = afterMarker.indexOf('/');
    if (firstSlash === -1) {
      Swal.fire({
        icon: 'error',
        title: 'Preview Failed',
        text: 'Invalid document URL format.',
      });
      return;
    }

    const bucketName = afterMarker.substring(0, firstSlash);
    const filePath = afterMarker.substring(firstSlash + 1);

    console.log('Fetching document:', { bucketName, filePath });

    this.userAccountService.viewDocument(bucketName, filePath).subscribe({
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

  previewImage(imageUrl: string): void {
    if (!imageUrl) {
      console.error('No image URL available to preview.');
      Swal.fire({
        icon: 'warning',
        title: 'No Image',
        text: 'There is no image URL provided.',
      });
      return;
    }

    const newWindow = window.open(imageUrl, '_blank');
    if (!newWindow) {
      Swal.fire({
        icon: 'error',
        title: 'Preview Failed',
        text: 'Unable to open the image. Please allow pop-ups for this site.',
      });
    }
  }

  compareImages(): void {
    console.log('Comparing images:');
    console.log('ID Image URL for comparison:', this.idImage, 'Is ID Image:', this.isIdImage);
    console.log('Face Image URL for comparison:', this.faceImage, 'Is Face Image:', this.isFaceImage);

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
