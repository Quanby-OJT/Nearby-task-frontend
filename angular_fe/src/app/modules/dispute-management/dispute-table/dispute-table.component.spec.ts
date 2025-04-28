import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DisputeTableComponent } from './dispute-table.component';

describe('DisputeTableComponent', () => {
  let component: DisputeTableComponent;
  let fixture: ComponentFixture<DisputeTableComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DisputeTableComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DisputeTableComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
