import { NgFor } from '@angular/common';
import { Component, OnInit } from '@angular/core';

@Component({
  selector: '[nft-auctions-table]',
  templateUrl: './nft-auctions-table.component.html',
  imports: [NgFor],
})
export class NftAuctionsTableComponent implements OnInit {
  public TaskTaken = [
    {
      client: 'Mike Smith',
      tasker: 'Jenny Wilson',
      ending_in: '1h 05m 00s',
      status: 'Cancelled'
    },
    {
      client: 'Sarah Johnson',
      tasker: 'Tom Brown',
      ending_in: '2h 30m 00s',
      status: 'Completed'
    },
    {
      client: 'John Doe',
      tasker: 'Emma Davis',
      ending_in: '45m 20s',
      status: 'Ongoing'
    },
    {
      client: 'Lisa Anderson',
      tasker: 'Mark Taylor',
      ending_in: '3h 15m 00s',
      status: 'Ongoing'
    },
    {
      client: 'Kora Doe',
      tasker: 'Bell Davis',
      ending_in: '4 days 50s',
      status: 'Ongoing'
    },
    {
      client: 'Baron Kevin',
      tasker: 'Dein Braken',
      ending_in: '10 days 30s',
      status: 'Completed'
    },
    {
      client: 'Steiin Kloe',
      tasker: 'Emma Davis',
      ending_in: '45m 20s',
      status: 'Ongoing'
    },
    {
      client: 'Sarah Johnson',
      tasker: 'Tom Brown',
      ending_in: '2h 30m 00s',
      status: 'Completed'
    },
  ];

  constructor() {}

  ngOnInit(): void {}
}