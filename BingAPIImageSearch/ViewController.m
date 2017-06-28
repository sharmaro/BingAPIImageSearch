//
//  ViewController.m
//  BingAPIImageSearch
//
//  Created by Rohan Sharma on 6/9/17.
//  Copyright © 2017 Zin. All rights reserved.
//

#import "ViewController.h"
#import "MyCollectionViewCell.h"

@interface ViewController () {
    NSMutableArray *imageUrlArray;
    NSMutableArray *imageContentUrlArray;
    
    // cellMap for ensuring images get loaded into the correct cells when user scrolls quickly
    NSMutableDictionary *cellMap;
    
    UIActivityIndicatorView *activityIndicatorView;
    
    NSMutableArray *userQueryImages;
    
    UIImage* placeHolderImage;
}
@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.searchBar.delegate = self;
    
    imageUrlArray = [[NSMutableArray alloc] init];
    imageContentUrlArray = [[NSMutableArray alloc] init];
    
    userQueryImages = [[NSMutableArray alloc] init];
    
    placeHolderImage = [UIImage imageNamed:@"placeHolderImage"];
    
    cellMap = [[NSMutableDictionary alloc] init];
    
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.transform = CGAffineTransformMakeScale(2.0, 2.0);
    activityIndicatorView.center = self.view.center;
    
    [self.collectionView addSubview:activityIndicatorView];
}

- (void)searchItem:(NSString *)userQuery {
    /// DO NOT CHANGE TO v7.0!!! DOESN'T WORK WITH THAT
    NSString* path = @"https://api.cognitive.microsoft.com/bing/v5.0/images/search";
    NSMutableString *qString = [[NSMutableString alloc] initWithString:@"q="];
    NSString* fixedUrlString = [userQuery stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    [qString appendString:fixedUrlString];
    NSArray* array = @[
                       // Request parameters
                       // Count is number of images
                       @"entities=true",
                       qString,
                       @"count=100",
                       @"offset=0",
                       @"mkt=en-us",
                       @"safeSearch=Moderate"
                       ];
    
    NSString* string = [array componentsJoinedByString:@"&"];
    path = [path stringByAppendingFormat:@"?%@", string];
    NSLog(@"GET: %@", path);
    
    NSMutableURLRequest* _request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    [_request setHTTPMethod:@"GET"];
    // Request headers
    [_request setValue:@"YOUR-KEY-HERE" forHTTPHeaderField:@"Ocp-Apim-Subscription-Key"];
    // Request body
    [_request setHTTPBody:[@"image" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    
    [[session dataTaskWithRequest:_request completionHandler:^(NSData * _Nullable connectionData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSLog(@"BEGAN GET request.");
        if (nil != error) {
            NSLog(@"Error: %@", error);
        } else {
            NSError* error = nil;
            NSMutableDictionary* json = nil;
            
            if (nil != connectionData) {
                NSLog(@"connectionData is NOT nil");
                json = [NSJSONSerialization JSONObjectWithData:connectionData options:NSJSONReadingMutableContainers error:&error];
            }
            
            if (error || !json) {
                NSLog(@"Could not parse loaded json with error:%@", error);
            }
            
            connectionData = nil;
            
            NSArray *jsonKeys = [json valueForKeyPath:@"value"];
            for(int i = 0; i < jsonKeys.count; i++) {
                [imageUrlArray addObject:[jsonKeys[i] valueForKeyPath:@"thumbnailUrl"]];
                [imageContentUrlArray addObject:[jsonKeys[i] valueForKeyPath:@"contentUrl"]];
            }
            [self.collectionView reloadData];
        }
        [activityIndicatorView stopAnimating];
    }] resume];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return imageUrlArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MyCollectionViewCell *cell = (MyCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell prepareForReuse];
    cell.imageView.image = placeHolderImage;
    
    NSString* cellMapKey = [NSString stringWithFormat:@"%li", (long)indexPath.row];
    NSURL* url = [NSURL URLWithString: [imageUrlArray objectAtIndex:indexPath.row]];
    [cellMap setValue:url forKey:cellMapKey];
    
    if (cell == nil) {
        cell = [[MyCollectionViewCell alloc]init];
    }
    
    if(userQueryImages.count <= indexPath.row) {
        NSLog(@"Image from image");
        // Load image in background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Load and decode image
            NSData * imageData = [NSData dataWithContentsOfURL:url];
            UIImage *image = [UIImage imageWithData:imageData];
            NSURL *cellUrl = [cellMap objectForKey:cellMapKey];
            [userQueryImages addObject:image];
            
            // Apply image on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                if(cellUrl == url) {
                    cell.imageView.image = image;
                }
            });
        });
    } else {
        NSLog(@"Image from userQueryImages");
        NSURL *cellUrl = [cellMap objectForKey:cellMapKey];
        if(cellUrl == url) {
            cell.imageView.image = userQueryImages[indexPath.row];
        }
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if(kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CollectionViewHeader" forIndexPath:indexPath];
        return headerView;
    }
    UICollectionReusableView *null;
    return null;
}

#pragma mark <UISeachBarDelegate>
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if([[searchBar text] length] > 0) {
        NSLog(@"BEGAN user search.");
        
        [imageUrlArray removeAllObjects];
        [cellMap removeAllObjects];
        [userQueryImages removeAllObjects];
        [activityIndicatorView startAnimating];
        NSLog(@"BEGAN enter searchItem() function.");
        [self searchItem:[searchBar text]];
        NSLog(@"END enter searchItem() function.");
        [searchBar resignFirstResponder];
        
        [self.collectionView reloadData];
        NSLog(@"END user search.");
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(![searchBar isFirstResponder]) {
        NSLog(@"[X] BUTTON CLICKED");
    }
}
@end
