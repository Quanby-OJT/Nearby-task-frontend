import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { SessionLocalStorage } from 'src/services/sessionStorage';
import { AuthService } from './services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const session = inject(SessionLocalStorage);
  const authservice = inject(AuthService);

  const sessionLocalStorage = session.getSession();
  const sessionFromStorage = sessionStorage.getItem('session') || '';

  if(!sessionLocalStorage) {
    setTimeout(() => {
      router.navigate(['/auth/sign-in']);
    }, 100);

    return false;
  }

  const cleanedStoredSessionID = sessionFromStorage.replace(/^"|"$/g, '').trim();
  const cleanedLocalStorage = sessionLocalStorage.replace(/^"|"$/g, '').trim();
  const cleanedLocalStorageTrim = JSON.parse(sessionLocalStorage);
  const finalCleanedLocalStorage = cleanedLocalStorageTrim.replace(/^"|"$/g, '').trim();

  console.log('Session from local storage:', finalCleanedLocalStorage);
  console.log('Session from session storage:', cleanedStoredSessionID);

  if (finalCleanedLocalStorage === cleanedStoredSessionID) {
    console.log('Match!');
    return true;
  } else {
    console.log('No match!');

    // Delay navigation to prevent immediate re-execution of authGuard
    if (finalCleanedLocalStorage) {
      console.log('From guard:', finalCleanedLocalStorage);
      authservice.logoutWithoutSession(finalCleanedLocalStorage).subscribe({
        next: () => {
          setTimeout(() => {
            router.navigate(['/auth/sign-in']);
          }, 100);

          return false;
        },
      });
    }

    setTimeout(() => {
      router.navigate(['/auth/sign-in']);
    }, 100);

    return false;
  }
};
