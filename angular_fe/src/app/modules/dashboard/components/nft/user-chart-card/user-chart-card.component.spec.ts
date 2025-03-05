import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UserChartCardComponent } from './user-chart-card.component';

describe('UserChartCardComponent', () => {
  let component: UserChartCardComponent;
  let fixture: ComponentFixture<UserChartCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserChartCardComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(UserChartCardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
