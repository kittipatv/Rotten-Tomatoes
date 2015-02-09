//
//  MovieDetailViewController.m
//  Rotten Tomatoes
//
//  Created by Kittipat Virochsiri on 2/8/15.
//  Copyright (c) 2015 Kittipat Virochsiri. All rights reserved.
//

#import "MovieDetailViewController.h"

#import <UIImageView+AFNetworking.h>

#import "MovieDetailTableViewCell.h"

@interface MovieDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MovieDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *originalImageStr = [[self.movieData valueForKeyPath:@"posters.original"] stringByReplacingOccurrencesOfString:@"_tmb." withString:@"_ori."];
    NSLog(@"%@", originalImageStr);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:originalImageStr] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:600];
    
    BOOL existed = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    NSLog(@"ori existed: %d", existed);
    
    UIImageView *posterView = [[UIImageView alloc] init];
    [posterView setImageWithURLRequest:request placeholderImage:self.thumbnailImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        double duration = existed ? 0.0 : 0.5;
        [UIView transitionWithView:posterView duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            posterView.image = image;
        } completion:nil];
    } failure:nil];
    
    self.tableView.backgroundView = posterView;
    
    self.title = self.movieData[@"title"];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MovieDetailTableViewCell" bundle:nil] forCellReuseIdentifier:@"MovieDetailCell"];
    
    self.tableView.sectionHeaderHeight = 400;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MovieDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieDetailCell" forIndexPath:indexPath];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@ (%@)",
                            self.movieData[@"title"], self.movieData[@"year"]];
    
    cell.mpaaRating.text = self.movieData[@"mpaa_rating"];
    NSDictionary *rating = self.movieData[@"ratings"];
    if (rating[@"critics_rating"]) {
        cell.criticRating.text = [NSString stringWithFormat:@"%@ (%@)", rating[@"critics_rating"], rating[@"critics_score"]];
    } else {
        cell.criticRating.text = @"n/a";
    }
    if (rating[@"audience_rating"]) {
        cell.audiencRating.text = [NSString stringWithFormat:@"%@ (%@)", rating[@"audience_rating"], rating[@"audience_score"]];
    } else {
        cell.audiencRating.text = @"n/a";
    }
    cell.synopsisLabel.text = self.movieData[@"synopsis"];
    [cell.synopsisLabel sizeToFit];
    self.tableView.rowHeight = cell.synopsisLabel.bounds.size.height + 16 + 58;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 1000)];
    return view;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
