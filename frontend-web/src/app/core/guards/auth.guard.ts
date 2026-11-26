import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { UserRole } from '../models';

export const authGuard: CanActivateFn = (_route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (!auth.isAuthenticated) return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
  return true;
};

export const roleGuard: CanActivateFn = route => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const roles = (route.data['roles'] ?? []) as UserRole[];
  if (!auth.isAuthenticated) return router.createUrlTree(['/login']);
  if (roles.length && !auth.hasRole(roles)) return router.createUrlTree(['/dashboard']);
  return true;
};
