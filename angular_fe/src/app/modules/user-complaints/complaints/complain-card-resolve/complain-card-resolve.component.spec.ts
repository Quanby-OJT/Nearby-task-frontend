import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ComplainCardResolveComponent } from './complain-card-resolve.component';

describe('ComplainCardResolveComponent', () => {
  let component: ComplainCardResolveComponent;
  let fixture: ComponentFixture<ComplainCardResolveComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ComplainCardResolveComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ComplainCardResolveComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
