import { User } from 'src/app/modules/uikit/pages/table/model/user.model';

export const dummyData: User[] = [
  {
    id: 1,
    name: 'John Doe',
    age: 30,
    username: 'johndoe',
    email: 'john.doe@example.com',
    phone: '+1-202-555-0156',
    website: 'johndoe.com',
    occupation: 'Software Engineer',
    hobbies: ['coding', 'hiking', 'reading'],
    selected: false,
    status: 1,
    created_at: '2024-10-12T12:34:56Z',
  },
];
