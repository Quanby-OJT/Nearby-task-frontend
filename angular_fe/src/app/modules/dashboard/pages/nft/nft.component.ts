import { Component, OnInit } from '@angular/core';
import { NftAuctionsTableComponent } from '../../components/nft/task-table/nft-auctions-table.component';
import { NftChartCardComponent } from '../../components/nft/nft-chart-card/nft-chart-card.component';
import { NftHeaderComponent } from '../../components/nft/header/nft-header.component';
import { NftSingleCardComponent } from '../../components/nft/single-card/nft-single-card.component';
import { Nft } from '../../models/nft';
import { UserChartCardComponent } from '../../components/nft/user-chart-card/user-chart-card.component';
import { UserAccountService } from 'src/app/services/userAccount';
import { CommonModule } from '@angular/common';

@Component({
  standalone: true,
  selector: 'app-nft',
  templateUrl: './nft.component.html',
  imports: [
    NftHeaderComponent,
    NftSingleCardComponent,
    NftChartCardComponent,
    NftAuctionsTableComponent,
    UserChartCardComponent,
    CommonModule
  ],
})
export class NftComponent implements OnInit {
  nft: Array<Nft>;
  adminCount: number = 0;
  moderatorCount: number = 0;
  clientCount: number = 0;
  taskerCount: number = 0;
  isLoading: boolean = true; 

  constructor(private userAccountService: UserAccountService) {
    this.nft = [
      {
        id: 34356771,
        title: 'Girls of the Cartoon Universe',
        creator: 'Jhon Doe',
        instant_price: 4.2,
        price: 187.47,
        ending_in: '06h 52m 47s',
        last_bid: 0.12,
        image: './assets/images/img-01.jpg',
        avatar: './assets/avatars/avt-01.jpg',
      },
      {
        id: 34356772,
        title: 'Number of Admins',
        price: 548.79,
        last_bid: 0.35,
        image: './assets/images/img-02.jpg',
      },
      {
        id: 34356773,
        title: 'Seeing Green collection',
        price: 234.88,
        last_bid: 0.15,
        image: './assets/images/img-03.jpg',
      },
    ];
  }

  ngOnInit(): void {
    this.isLoading = true; 
    this.userAccountService.getAllUsers().subscribe(
      data => {
        const users = data.users;
        this.adminCount = users.filter((user: { user_role: string }) => user.user_role === 'Admin').length;
        this.moderatorCount = users.filter((user: { user_role: string }) => user.user_role === 'Moderator').length;
        this.clientCount = users.filter((user: { user_role: string }) => user.user_role === 'Client').length;
        this.taskerCount = users.filter((user: { user_role: string }) => user.user_role === 'Tasker').length;
        this.isLoading = false; 
      },
      error => {
        console.error('Error fetching users:', error);
        this.isLoading = false; 
      }
    );
  }
}