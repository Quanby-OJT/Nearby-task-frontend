import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DisputeManagementComponent } from './dispute-management.component';

describe('DisputeManagementComponent', () => {
  let component: DisputeManagementComponent;
  let fixture: ComponentFixture<DisputeManagementComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DisputeManagementComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DisputeManagementComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
