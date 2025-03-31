import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TaskerComplaintComponent } from './tasker-complaint.component';

describe('TaskerComplaintComponent', () => {
  let component: TaskerComplaintComponent;
  let fixture: ComponentFixture<TaskerComplaintComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TaskerComplaintComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(TaskerComplaintComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
