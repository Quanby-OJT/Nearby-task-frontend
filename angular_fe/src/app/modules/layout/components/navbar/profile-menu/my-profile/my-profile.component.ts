import { Component, OnInit, AfterViewInit, ChangeDetectorRef, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from 'src/app/services/auth.service';
import { UserAccountService } from 'src/app/services/userAccount';
import { Users } from 'src/model/user-management';
import { toast } from 'ngx-sonner';
import Swal from 'sweetalert2';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { LoadingService } from 'src/app/services/loading.service';
import {
  ReactiveFormsModule,
  FormGroup,
  FormControl,
  Validators,
  FormBuilder,
  ValidatorFn
} from '@angular/forms';
import { Router } from '@angular/router';

interface Address {
  id?: string;
  barangay?: string;
  city?: string;
  province?: string;
  postal_code?: string;
  country?: string;
  street?: string;
  default?: boolean;
}

@Component({
  selector: 'app-my-profile',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    AngularSvgIconModule
  ],
  templateUrl: './my-profile.component.html',
  styleUrl: './my-profile.component.css'
})
export class MyProfileComponent implements OnInit, AfterViewInit {
  user: Users | null = null;
  address: Address | null = null;
  addresses: Address[] = [];
  isLoading: boolean = true;
  isSaving: boolean = false;
  profileForm!: FormGroup;
  submitted = false;
  imageUrl: string | null = null;
  showPassword: boolean = false; 
  showConfirmPassword: boolean = false; 
  today: string; 

  @ViewChild('birthdateInput') birthdateInput!: ElementRef<HTMLInputElement>;

  constructor(
    private authService: AuthService,
    private router: Router,
    private userAccountService: UserAccountService,
    private fb: FormBuilder,
    private cdr: ChangeDetectorRef,
    private loadingService: LoadingService
  ) {
    const now = new Date();
    this.today = now.toISOString().split('T')[0];
  }

  ngOnInit() {
    this.loadingService.show();
    this.isLoading = true;
    this.authService.userInformation().subscribe(
      (response: any) => {
        console.log('User Information for Profile:', response.user);
        this.user = response.user;
        this.initializeForm();
        this.imageUrl = this.user?.image_link || null;
        this.getAddresses();
        this.isLoading = false;
        this.loadingService.hide();
        this.cdr.detectChanges(); 
      },
      (error: any) => {
        console.error('Error fetching user for profile:', error);
        toast.error('Failed to load profile information.');
        this.isLoading = false;
        this.loadingService.hide();
        this.cdr.detectChanges(); 
      }
    );
  }

  ngAfterViewInit() {
    if (this.birthdateInput) {
      this.birthdateInput.nativeElement.setAttribute('max', this.today);
    }
  }

  private maxDateValidator(maxDate: string): ValidatorFn {
    return (control) => {
      if (!control.value) return null;
      const selectedDate = new Date(control.value);
      const max = new Date(maxDate);
      return selectedDate > max ? { futureDate: true } : null;
    };
  }

  initializeForm() {
    if (!this.user) return;
    this.profileForm = this.fb.group({
      first_name: [this.user.first_name, Validators.required],
      middle_name: [this.user.middle_name],
      last_name: [this.user.last_name, Validators.required],
      email: [{ value: this.user.email, disabled: true }],
      newPassword: ['', [Validators.minLength(8)]],
      confirmPassword: [''],
      contact: [this.user.contact],
      gender: [this.user.gender],
      birthdate: [this.user.birthdate ? new Date(this.user.birthdate).toISOString().split('T')[0] : this.today, [Validators.required, this.maxDateValidator(this.today)]],
      profileImage: [null],
      street: [''],
      barangay: [''],
      city: [''],
      province: [''],
      postal_code: [''],
      country: [''],
      default: [false]
    }, { validators: this.passwordMatchValidator });
  }

  passwordMatchValidator(form: FormGroup) {
    const newPassword = form.get('newPassword')?.value;
    const confirmPassword = form.get('confirmPassword')?.value;
    if (newPassword && confirmPassword && newPassword !== confirmPassword) {
      form.get('confirmPassword')?.setErrors({ mismatch: true });
    } else {
      form.get('confirmPassword')?.setErrors(null);
    }
    return null;
  }

  get f() { return this.profileForm.controls; }

  onFileChange(event: Event) {
    const element = event.currentTarget as HTMLInputElement;
    let fileList: FileList | null = element.files;
    if (fileList && fileList.length > 0) {
      const file = fileList[0];
      this.profileForm.patchValue({ profileImage: file });
      const reader = new FileReader();
      reader.onload = () => {
        this.imageUrl = reader.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  confirmSave() {
    Swal.fire({
      title: 'Are you sure?',
      text: 'Are you sure you want to change your personal information?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Yes',
      cancelButtonText: 'Cancel',
      buttonsStyling: true,
      customClass: {
        confirmButton: 'bg-primary text-primary-foreground hover:bg-primary/90 inline-flex justify-center rounded-md border border-transparent py-2 px-4 text-sm font-medium shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary',
        cancelButton: 'bg-gray-300 text-gray-700 hover:bg-gray-400 inline-flex justify-center rounded-md border border-transparent py-2 px-4 text-sm font-medium shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-300'
      }
    }).then((result) => {
      if (result.isConfirmed) {
        this.onSubmit();
      }
    });
  }

  onSubmit() {
    this.submitted = true;

    if (this.profileForm.invalid) {
      toast.error('Please fill all required fields correctly.');
      console.log('Form Errors:', this.profileForm.errors);
      Object.keys(this.profileForm.controls).forEach(key => {
        const controlErrors = this.profileForm.get(key)?.errors;
        if (controlErrors != null) {
          console.log('Key control: ' + key + ', errors: ', controlErrors);
        }
      });
      return;
    }

    if (!this.user?.user_id) {
      toast.error('User ID is missing. Cannot update profile.');
      return;
    }

    this.isSaving = true;
    const formData = new FormData();

    Object.keys(this.profileForm.value).forEach(key => {
      if (key !== 'email' && key !== 'profileImage' && key !== 'newPassword' && key !== 'confirmPassword') {
        const value = this.profileForm.value[key];
        if (value !== null && value !== undefined) {
          formData.append(key, value);
        }
      }
    });

    const profileImageFile = this.profileForm.get('profileImage')?.value;
    if (profileImageFile instanceof File) {
      formData.append('image', profileImageFile, profileImageFile.name);
    }

    console.log('Submitting Form Data via UserAccountService:', formData);

    this.userAccountService.updateAuthorityUser(this.user.user_id, formData).subscribe({
      next: (response) => {
        const newPassword = this.profileForm.get('newPassword')?.value;
        const addressUpdate = () => {
          const addressData = {
            user_id: this.user!.user_id,
            street: this.profileForm.get('street')?.value,
            barangay: this.profileForm.get('barangay')?.value,
            city: this.profileForm.get('city')?.value,
            province: this.profileForm.get('province')?.value,
            postal_code: this.profileForm.get('postal_code')?.value,
            country: this.profileForm.get('country')?.value,
            default: this.profileForm.get('default')?.value
          };

          // Check if address fields are filled
          const hasAddressData = Object.values(addressData).some(val => val !== '' && val !== null && val !== undefined);

          if (!hasAddressData) {
            this.handleSuccess('Profile updated successfully!');
            this.user = response.user ? { ...(this.user as Users), ...response.user } : this.user;
            this.imageUrl = this.user?.image_link || null;
            this.isSaving = false;
            this.submitted = false;
            return;
          }

          if (this.address && this.address.id) {
            // Update existing address
            this.userAccountService.updateAddress(this.address.id, addressData).subscribe({
              next: () => {
                this.handleSuccess('Changes updated successfully!');
                this.user = response.user ? { ...(this.user as Users), ...response.user } : this.user;
                this.imageUrl = this.user?.image_link || null;
                this.isSaving = false;
                this.submitted = false;
                this.getAddresses();
              },
              error: (error) => {
                console.error('Error updating address:', error);
                toast.error(error?.error?.message || 'Failed to update address.');
                this.isSaving = false;
              }
            });
          } else {
            // Add new address
            this.userAccountService.addAddress(addressData).subscribe({
              next: () => {
                this.handleSuccess('Profile and address added successfully!');
                this.user = response.user ? { ...(this.user as Users), ...response.user } : this.user;
                this.imageUrl = this.user?.image_link || null;
                this.isSaving = false;
                this.submitted = false;
                this.getAddresses();
              },
              error: (error) => {
                console.error('Error adding address:', error);
                toast.error(error?.error?.message || 'Failed to add address.');
                this.isSaving = false;
              }
            });
          }
        };

        if (newPassword) {
          this.userAccountService.updatePassword(this.user!.email, newPassword).subscribe({
            next: () => {
              addressUpdate();
              this.profileForm.get('newPassword')?.reset();
              this.profileForm.get('confirmPassword')?.reset();
            },
            error: (error) => {
              console.error('Error updating password:', error);
              toast.error(error?.error?.message || 'Failed to update password.');
              this.isSaving = false;
            }
          });
        } else {
          addressUpdate();
        }
      },
      error: (error) => {
        console.error('Error updating profile:', error);
        toast.error(error?.error?.message || 'Failed to update profile.');
        this.isSaving = false;
      }
    });
  }

  private handleSuccess(message: string) {
    Swal.fire({
      title: 'Success!',
      text: message,
      icon: 'success',
      confirmButtonText: 'OK',
      buttonsStyling: true,
      customClass: {
        confirmButton: 'bg-primary text-primary-foreground hover:bg-primary/90 inline-flex justify-center rounded-md border border-transparent py-2 px-4 text-sm font-medium shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary'
      }
    }).then(() => {
      window.location.reload();
    });
  }

  getAddresses() {
    if (!this.user?.user_id) {
      console.warn('User ID is missing. Cannot fetch addresses.');
      toast.error('User ID is missing. Cannot fetch addresses.');
      return;
    }

    const userId = this.user.user_id;
    console.log(`Attempting to fetch addresses for user ID: ${userId}`);

    this.userAccountService.getAddresses(userId).subscribe({
      next: (response) => {
        console.log(`Raw response from getAddresses for user ${userId}:`, response);
        // Access the nested 'address' array within the 'data' property
        const addressesData = response?.data?.address;

        if (addressesData && Array.isArray(addressesData)) {
           console.log(`Addresses found for user ${userId}:`, addressesData);
          this.addresses = addressesData;
          // Use the first address if available
          if (this.addresses.length > 0) {
            this.address = this.addresses[0];
            console.log(`Using the first address:`, this.address);
            this.profileForm.patchValue({
              street: this.address.street || '',
              barangay: this.address.barangay || '',
              city: this.address.city || '',
              province: this.address.province || '',
              postal_code: this.address.postal_code || '',
              country: this.address.country || '',
              default: this.address.default || false
            });
             console.log(`Form patched with address data for user ${userId}. Current form value:`, this.profileForm.value);
          } else {
             console.log(`No addresses found for user ${userId}.`);
             // Clear address fields if no address found
             this.profileForm.patchValue({
              street: '',
              barangay: '',
              city: '',
              province: '',
              postal_code: '',
              country: '',
              default: false
            });
          }
        } else {
           console.warn(`Response from getAddresses for user ${userId} did not contain expected data structure:`, response);
           // Clear address fields if response is unexpected or addresses array is missing/not array
             this.profileForm.patchValue({
              street: '',
              barangay: '',
              city: '',
              province: '',
              postal_code: '',
              country: '',
              default: false
            });
        }

        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error(`Error fetching addresses for user ${userId}:`, error);
        toast.error('Failed to load addresses.');
        this.cdr.detectChanges(); // Ensure view updates even on error
      }
    });
  }

  dashboard() {
    this.router.navigate(['/dashboard']);
  }

  togglePasswordVisibility(field: string) {
    if (field === 'newPassword') {
      this.showPassword = !this.showPassword;
    } else if (field === 'confirmPassword') {
      this.showConfirmPassword = !this.showConfirmPassword;
    }
  }
}