import { TestBed } from '@angular/core/testing';

import { DisputeManagementService } from './dispute-management.service';

describe('DisputeManagementService', () => {
  let service: DisputeManagementService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(DisputeManagementService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
