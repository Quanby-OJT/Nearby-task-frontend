import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DisputeFilterComponent } from './dispute-filter.component';

describe('DisputeFilterComponent', () => {
  let component: DisputeFilterComponent;
  let fixture: ComponentFixture<DisputeFilterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DisputeFilterComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DisputeFilterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
