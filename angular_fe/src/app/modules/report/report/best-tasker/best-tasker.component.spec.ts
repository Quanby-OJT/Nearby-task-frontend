import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BestTaskerComponent } from './best-tasker.component';

describe('BestTaskerComponent', () => {
  let component: BestTaskerComponent;
  let fixture: ComponentFixture<BestTaskerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BestTaskerComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(BestTaskerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
