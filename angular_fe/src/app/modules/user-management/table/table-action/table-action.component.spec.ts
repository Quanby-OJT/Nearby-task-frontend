import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UserTableActionComponent } from './table-action.component';

describe('TableActionComponent', () => {
  let component: UserTableActionComponent;
  let fixture: ComponentFixture<UserTableActionComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserTableActionComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(UserTableActionComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
