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
#import "MovieCollectionViewCell.h"

@interface MoviesViewController () <UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet UITabBarItem *boxOfficeBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *dvdBarItem;
@property (weak, nonatomic) IBOutlet UITableView *moviesTableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (IBAction)onChange:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *viewChooser;

@property (weak, nonatomic) UIView *activeView;
@property (weak, nonatomic) UITabBarItem *previouslySelectedBarItem;

@property (strong, nonatomic) UIView *noConnectionView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSArray *movies;
@property (strong, nonatomic) NSString *endpoint;

@end

@implementation MoviesViewController

- (IBAction)onChange:(id)sender {
    if (sender == self.viewChooser) {
        UIView *toRemove = nil;
        UIView *toInsert = nil;
        if (self.viewChooser.selectedSegmentIndex == 0) {
            toRemove = self.collectionView;
            toInsert = self.moviesTableView;
        } else {
            toRemove = self.moviesTableView;
            toInsert = self.collectionView;
        }
        toRemove.hidden = YES;
        toInsert.hidden = NO;
        [toInsert insertSubview:self.refreshControl atIndex:0];
        self.activeView = toInsert;
        if (self.noConnectionView.superview) {
            [self.activeView insertSubview:self.noConnectionView aboveSubview:self.activeView];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.moviesTableView registerNib:[UINib nibWithNibName:@"MovieTableViewCell" bundle:nil] forCellReuseIdentifier:@"MovieTableViewCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"MovieCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"MovieCollectionViewCell"];
    
    self.moviesTableView.delegate = self;
    self.moviesTableView.dataSource = self;
    
    [self setBoxOfficEndpoint];
    
    [SVProgressHUD showWithStatus:@"Loading movie list"];
    [self loadMovieList];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventValueChanged];
    [self.moviesTableView insertSubview:self.refreshControl atIndex:0];
    
    self.title = @"Rotten Tomatoes";
    
    self.activeView = self.moviesTableView;
    
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
            [self.activeView insertSubview:self.noConnectionView aboveSubview:self.activeView];
        } else {
            [self.noConnectionView removeFromSuperview];
        }
    }];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Movies" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.tabBar.delegate = self;
    
    self.previouslySelectedBarItem = self.boxOfficeBarItem;
    self.tabBar.selectedItem = self.boxOfficeBarItem;
    
    self.moviesTableView.sectionHeaderHeight = 0;
    
    self.searchBar.delegate = self;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.hidden = YES;
}

- (void)setBoxOfficEndpoint {
    self.endpoint = @"http://api.rottentomatoes.com/api/public/v1.0/lists/movies/box_office.json";
}

- (void)setDVDEndpoint {
    self.endpoint = @"http://api.rottentomatoes.com/api/public/v1.0/lists/dvds/new_releases.json";
}

- (void)loadMovieList {
    [self requestWithParams:nil];
}

- (void)requestWithParams:(NSDictionary *)paramsOrNil {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"3hc6zpaxvqrwe58evfuub7xy", @"apikey", nil];
    if (paramsOrNil) {
        [params addEntriesFromDictionary:paramsOrNil];
    }
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:self.endpoint parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        self.movies = responseObject[@"movies"];
        [self.moviesTableView reloadData];
        [self.collectionView reloadData];
        [self.refreshControl endRefreshing];
        [SVProgressHUD popActivity];
        NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.moviesTableView scrollToRowAtIndexPath:topIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [self.collectionView scrollToItemAtIndexPath:topIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self.refreshControl endRefreshing];
        [SVProgressHUD popActivity];
    }];
}

- (void)onRefresh {
    if (self.searchBar.text.length == 0) {
        [self loadMovieList];
    } else {
        [self performSearch];
    }
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

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if (self.searchBar.text.length > 0) {
        self.previouslySelectedBarItem = nil;
    }
    self.searchBar.text = @"";
    if (self.previouslySelectedBarItem == item) {
        NSLog(@"Same");
        return;
    }
    self.previouslySelectedBarItem = item;
    [self loadListForSelectedTab];
}

- (void)loadListForSelectedTab {
    if (self.previouslySelectedBarItem == self.boxOfficeBarItem) {
        [self setBoxOfficEndpoint];
    } else {
        [self setDVDEndpoint];
    }
    [SVProgressHUD showWithStatus:@"Loading movie list"];
    [self loadMovieList];
}

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
    MovieTableViewCell *cell = (MovieTableViewCell *)[self.moviesTableView cellForRowAtIndexPath:indexPath];
    [self openDetailViewAtIndexPath:indexPath thumbnailImage:cell.posterImage.image];
}

- (void)openDetailViewAtIndexPath:(NSIndexPath *)indexPath thumbnailImage:(UIImage *)thumbnailImage {
    // Initialize the detail view
    MovieDetailViewController *movieDetailView = [[MovieDetailViewController alloc] init];
    movieDetailView.movieData = self.movies[indexPath.row];
    
    movieDetailView.thumbnailImage = thumbnailImage;
    
    // Push the deatail view
    [[self navigationController] pushViewController:movieDetailView animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        [self loadListForSelectedTab];
        return;
    }
    [SVProgressHUD showWithStatus:@"Searching"];
    [self performSearch];
}

    
- (void)performSearch {
    self.endpoint = @"http://api.rottentomatoes.com/api/public/v1.0/movies.json";
    [self requestWithParams:@{
                              @"q":self.searchBar.text,
                              @"page_limit":@"20"
                              }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self loadListForSelectedTab];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"cv number items: %ld", self.movies.count);
    return self.movies.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    MovieCollectionViewCell *cell = (MovieCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self openDetailViewAtIndexPath:indexPath thumbnailImage:cell.posterImage.image];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cv cell %@", indexPath);
    MovieCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"MovieCollectionViewCell" forIndexPath:indexPath];
    
    NSDictionary *movie = self.movies[indexPath.row];
    cell.titleLabel.text = movie[@"title"];
    
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(90, 140);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

@end
