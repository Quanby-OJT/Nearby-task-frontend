import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TaskerComplainTabComponent } from './tasker-complain-tab.component';

describe('TaskerComplainTabComponent', () => {
  let component: TaskerComplainTabComponent;
  let fixture: ComponentFixture<TaskerComplainTabComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TaskerComplainTabComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(TaskerComplainTabComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
