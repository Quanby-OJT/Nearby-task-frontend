import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UserTableFooterComponent } from './table-footer.component';

describe('TableFooterComponent', () => {
  let component: UserTableFooterComponent;
  let fixture: ComponentFixture<UserTableFooterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserTableFooterComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(UserTableFooterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
