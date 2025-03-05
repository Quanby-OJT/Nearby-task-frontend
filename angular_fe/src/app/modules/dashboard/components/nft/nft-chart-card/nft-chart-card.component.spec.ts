import { ComponentFixture, TestBed } from '@angular/core/testing';

import { RevenueChart } from './nft-chart-card.component';

describe('NftChartCardComponent', () => {
  let component: RevenueChart;
  let fixture: ComponentFixture<RevenueChart>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RevenueChart],
    }).compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(RevenueChart);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
