import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CreateSpecializationComponent } from './create-specialization.component';

describe('CreateSpecializationComponent', () => {
  let component: CreateSpecializationComponent;
  let fixture: ComponentFixture<CreateSpecializationComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CreateSpecializationComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CreateSpecializationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
