import { NgFor } from '@angular/common';
import { Component, OnInit } from '@angular/core';
// import { Nft } from '../../../models/nft';
import { task_taken } from '../../../models/task_taken';
import { NftAuctionsTableItemComponent } from '../task-table-item/nft-auctions-table-item.component';

@Component({
  selector: '[nft-auctions-table]',
  templateUrl: './nft-auctions-table.component.html',
  imports: [NgFor, NftAuctionsTableItemComponent],
})
export class NftAuctionsTableComponent implements OnInit {
  public TaskTaken: task_taken[] = [];

  constructor() {
    this.TaskTaken = [
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Cancelled',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Completed',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Completed',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Cancelled',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Ongoing',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Ongoing',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Ongoing',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Ongoing',
      },
      {
        id: 1346792,
        client: 'Mike Smith',
        tasker: 'Jenny Wilson',
        task_id: 1346792,
        ending_in: '1h 05m 00s',
        status: 'Ongoing',
      },
    ];
  }

  ngOnInit(): void {}
}
