import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BestClientComponent } from './best-client.component';

describe('BestClientComponent', () => {
  let component: BestClientComponent;
  let fixture: ComponentFixture<BestClientComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [BestClientComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(BestClientComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
