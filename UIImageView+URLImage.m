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
    
    //缓存里找，有则设置图片
    [ZCImageManager searchImageFromMemoryWithURL:url completion:^(BOOL isExist, UIImage *image) {
        if(isExist) {
            self.image = image;
            return;
        }
        
        //disk 里面找，有则设置图片
        [ZCImageManager searchImageFromDiskWithURL:url completion:^(BOOL isExist, UIImage *image) {
            if(isExist) {
                self.image = image;
                return;
            }
            
            //加载网络图片
            [ZCImageManager loadImage:url clompletion:^(BOOL isExist, UIImage *image) {
                if(isExist) {
                    self.image = image;
                }
            }];
        }];
    }];
    
    
    
    
}
@end
