//
//  MyCollectionViewCell.m
//  BingAPIImageSearch
//
//  Created by Rohan Sharma on 6/9/17.
//  Copyright © 2017 Zin. All rights reserved.
//

#import "MyCollectionViewCell.h"

@interface MyCollectionViewCell() {
    UIImage* placeHolderImage;
}
@end

@implementation MyCollectionViewCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        placeHolderImage = [UIImage imageNamed:@"placeHolderImage"];
        self.imageView.image = placeHolderImage;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = placeHolderImage;
}

@end
