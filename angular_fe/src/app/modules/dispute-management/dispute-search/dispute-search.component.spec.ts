import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DisputeSearchComponent } from './dispute-search.component';

describe('DisputeSearchComponent', () => {
  let component: DisputeSearchComponent;
  let fixture: ComponentFixture<DisputeSearchComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DisputeSearchComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DisputeSearchComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
