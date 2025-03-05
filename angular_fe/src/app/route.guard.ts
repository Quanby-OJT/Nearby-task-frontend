import { inject } from '@angular/core';
import { CanActivateFn } from '@angular/router';
import { map } from 'rxjs';
import { DataService } from 'src/services/dataStorage';
import { Router } from '@angular/router';

export const routeGuard: CanActivateFn = (route, state) => {
  const dataService = inject(DataService);
  const router = inject(Router);

  return dataService.getUserRole().pipe(
    map((userRole) => {
      if (userRole === 'admin' || userRole === 'moderator') {
        return true;
      } else {
        router.navigate(['/error']);
        return false;
      }
    }),
  );
};
