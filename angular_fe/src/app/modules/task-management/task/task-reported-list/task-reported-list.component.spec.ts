import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TaskReportedListComponent } from './task-reported-list.component';

describe('TaskReportedListComponent', () => {
  let component: TaskReportedListComponent;
  let fixture: ComponentFixture<TaskReportedListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TaskReportedListComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(TaskReportedListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
