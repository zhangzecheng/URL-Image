//
//  UIImageView+URLImage.m
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import "UIImageView+URLImage.h"
#import "ZCImageManager.h"

@implementation UIImageView (URLImage)
- (void)loadURLImageWith:(NSString *)url placeImage:(UIImage *)placeImage {
    self.image = placeImage;
    [ZCImageManager setShowLoadingAnimation:YES];
    [ZCImageManager loadImageSource:url clompletion:^(BOOL isExist, UIImage *image) {
        if(isExist) {
            self.image = image;
        }
    }];
    
}
@end
