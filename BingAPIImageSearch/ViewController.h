//
//  ViewController.h
//  BingAPIImageSearch
//
//  Created by Rohan Sharma on 6/9/17.
//  Copyright © 2017 Zin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

