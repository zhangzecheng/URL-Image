//
//  UIImageView+URLImage.h
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (URLImage)
/**
 *  @brief 加载网络图片
 *
 *  @param url 图片链接
 *  @param placeImage 占位图
 */
- (void)loadURLImageWith:(NSString *)url placeImage:(UIImage *)placeImage;


@end

