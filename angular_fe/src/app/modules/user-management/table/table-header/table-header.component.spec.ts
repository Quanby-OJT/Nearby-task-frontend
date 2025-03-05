import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserTableHeaderComponent } from './table-header.component';

describe('TableHeaderComponent', () => {
  let component: UserTableHeaderComponent;
  let fixture: ComponentFixture<UserTableHeaderComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserTableHeaderComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(UserTableHeaderComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
