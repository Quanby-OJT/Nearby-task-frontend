import { task_taken } from '../../../models/task_taken';
import { CurrencyPipe } from '@angular/common';
import { Component, Input, OnInit } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { Nft } from '../../../models/nft';

@Component({
  selector: '[nft-auctions-table-item]',
  templateUrl: './nft-auctions-table-item.component.html',
  imports: [AngularSvgIconModule, CurrencyPipe],
})
export class NftAuctionsTableItemComponent implements OnInit {
  @Input() TaskTaken = <task_taken>{};

  constructor() {}

  ngOnInit(): void {}
}
