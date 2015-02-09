//
//  MovieCollectionViewCell.h
//  Rotten Tomatoes
//
//  Created by Kittipat Virochsiri on 2/8/15.
//  Copyright (c) 2015 Kittipat Virochsiri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *posterImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
