import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UserTableRowComponent } from './table-row.component';

describe('TableContentComponent', () => {
  let component: UserTableRowComponent;
  let fixture: ComponentFixture<UserTableRowComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserTableRowComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(UserTableRowComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
