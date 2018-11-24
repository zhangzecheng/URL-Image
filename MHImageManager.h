//
//  MHImageManager.h
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^MHImageCompletion)(BOOL isExist,UIImage *image);

@interface MHImageManager : NSObject
/*
 *  @brief 查找缓存里的图片
 *
 *  @param url 图片路径
 *  @param completion 回调
 */
+ (void)searchImageFromMemoryWithURL:(NSString *)url
                          completion:(MHImageCompletion)completion;

/*
 *  @brief 查找硬盘的图片
 *
 *  @param url 图片路径
 *  @param completion 回调
 */
+ (void)searchImageFromDiskWithURL:(NSString *)url
                        completion:(MHImageCompletion)completion;

/*
 *  @brief 加载网络图片
 *
 *  @param url 图片路径
 *  @param completion 回调
 */
+ (void)loadImage:(NSString *)url clompletion:(MHImageCompletion)completion;

/*
 *  @brief 清除缓存里的图片
 */
+ (void)clearImageFromMemory;

/*
 *  @brief 清除硬盘里的图片
 */
+ (void)clearImageFromDisk;
@end
