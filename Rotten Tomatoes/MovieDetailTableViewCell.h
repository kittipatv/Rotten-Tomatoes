//
//  MovieDetailTableViewCell.h
//  Rotten Tomatoes
//
//  Created by Kittipat Virochsiri on 2/8/15.
//  Copyright (c) 2015 Kittipat Virochsiri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieDetailTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *mpaaRating;
@property (weak, nonatomic) IBOutlet UILabel *criticRating;
@property (weak, nonatomic) IBOutlet UILabel *audiencRating;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *synopsisLabel;

@end
