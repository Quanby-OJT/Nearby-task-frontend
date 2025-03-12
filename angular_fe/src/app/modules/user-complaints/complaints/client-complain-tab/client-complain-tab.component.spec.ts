import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ClientComplainTabComponent } from './client-complain-tab.component';

describe('ClientComplainTabComponent', () => {
  let component: ClientComplainTabComponent;
  let fixture: ComponentFixture<ClientComplainTabComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ClientComplainTabComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ClientComplainTabComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
