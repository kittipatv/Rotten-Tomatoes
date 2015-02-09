//
//  MovieDetailViewController.h
//  Rotten Tomatoes
//
//  Created by Kittipat Virochsiri on 2/8/15.
//  Copyright (c) 2015 Kittipat Virochsiri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieDetailViewController : UIViewController

@property (weak, nonatomic) UIImage *thumbnailImage;
@property (strong, nonatomic) NSDictionary *movieData;

@end
