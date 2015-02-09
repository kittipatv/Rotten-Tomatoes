//
//  MoviesViewController.m
//  Rotten Tomatoes
//
//  Created by Kittipat Virochsiri on 2/3/15.
//  Copyright (c) 2015 Kittipat Virochsiri. All rights reserved.
//

#import <AFNetworking.h>
#import <UIImageView+AFNetworking.h>
#import <AFNetworkReachabilityManager.h>
#import <SVProgressHUD.h>

#import "MoviesViewController.h"
#import "MovieTableViewCell.h"
#import "MovieDetailViewController.h"

@interface MoviesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *moviesTableView;

@property (strong, nonatomic) UIView *noConnectionView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSArray *movies;

@end

@implementation MoviesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.moviesTableView registerNib:[UINib nibWithNibName:@"MovieTableViewCell" bundle:nil] forCellReuseIdentifier:@"MovieTableViewCell"];
    
    self.moviesTableView.delegate = self;
    self.moviesTableView.dataSource = self;
    
    [SVProgressHUD showWithStatus:@"Loading movie list"];
    [self loadMovieList];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    [self.moviesTableView insertSubview:self.refreshControl atIndex:0];
    
    self.title = @"Rotten Tomatoes";
    
    self.noConnectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    self.noConnectionView.backgroundColor = [UIColor redColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    label.text = @"No network connection";
    label.textAlignment = NSTextAlignmentCenter;
    [self.noConnectionView addSubview:label];
    
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    [reachabilityManager startMonitoring];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"status: %ld", status);
        if (status == AFNetworkReachabilityStatusNotReachable) {
            [self.moviesTableView insertSubview:self.noConnectionView aboveSubview:self.moviesTableView];
        } else {
            [self.noConnectionView removeFromSuperview];
        }
    }];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Movies" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)loadMovieList {
    NSDictionary *params = @{
                            @"apikey":@"3hc6zpaxvqrwe58evfuub7xy"
                            };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"http://api.rottentomatoes.com/api/public/v1.0/lists/movies/box_office.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        self.movies = responseObject[@"movies"];
        [self.moviesTableView reloadData];
        [self.refreshControl endRefreshing];
        [SVProgressHUD popActivity];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self.refreshControl endRefreshing];
        [SVProgressHUD popActivity];
    }];
}

- (void)onRefresh {
    [self loadMovieList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.movies count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MovieTableViewCell *cell = [self.moviesTableView dequeueReusableCellWithIdentifier:@"MovieTableViewCell"];
    id movie = self.movies[indexPath.row];
    cell.titleLabel.text = movie[@"title"];
    cell.synopsisLabel.text = movie[@"synopsis"];
    NSURL *posterURL = [NSURL URLWithString:[movie valueForKeyPath:@"posters.thumbnail"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:posterURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:600];
    BOOL existed = [[NSURLCache sharedURLCache] cachedResponseForRequest:request] != nil;
    NSLog(@"existed: %d", existed);
    [cell.posterImage setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        double duration = existed ? 0.0 : 0.5;
        [UIView transitionWithView:cell.posterImage duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            cell.posterImage.image = image;
        } completion:nil];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"fail to load %@, error %@", request, error);
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.moviesTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Initialize the detail view
    MovieDetailViewController *movieDetailView = [[MovieDetailViewController alloc] init];
    movieDetailView.movieData = self.movies[indexPath.row];
    
    MovieTableViewCell *cell = (MovieTableViewCell *)[self.moviesTableView cellForRowAtIndexPath:indexPath];
    movieDetailView.thumbnailImage = cell.posterImage.image;
    
    // Push the deatail view
    [[self navigationController] pushViewController:movieDetailView animated:YES];
}

@end
