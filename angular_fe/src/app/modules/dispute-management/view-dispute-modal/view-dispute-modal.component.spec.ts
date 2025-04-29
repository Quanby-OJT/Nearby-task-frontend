import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ViewDisputeModalComponent } from './view-dispute-modal.component';

describe('ViewDisputeModalComponent', () => {
  let component: ViewDisputeModalComponent;
  let fixture: ComponentFixture<ViewDisputeModalComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ViewDisputeModalComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ViewDisputeModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
