//
//  ZCImageManager.h
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^ZCImageCompletion)(BOOL isExist,UIImage *image);

@interface ZCImageManager : NSObject
/*
 *  @brief 查找缓存里的图片
 *
 *  @param url 图片路径
 *  @param completion 回调
 */
+ (void)searchImageFromMemoryWithURL:(NSString *)url
                          completion:(ZCImageCompletion)completion;

/*
 *  @brief 查找硬盘的图片
 *
 *  @param url 图片路径
 *  @param completion 回调
 */
+ (void)searchImageFromDiskWithURL:(NSString *)url
                        completion:(ZCImageCompletion)completion;

/*
 *  @brief 下载网络图片
 *
 *  @param url 图片路径
 *  @param completion 回调
 */
+ (void)downloadImage:(NSString *)url
          clompletion:(ZCImageCompletion)completion;

/*
 *  @brief 加载网络图片,包含了“查找缓存里的图片”、“查找硬盘的图片”、“下载网络图片”三个步骤
 *
 *  @param url 图片路径
 *  @param completion 回调
 */
+ (void)loadImage:(NSString *)url
      clompletion:(ZCImageCompletion)completion;

/*
 *  @brief 清除缓存里的图片
 */
+ (void)clearImageFromMemory;

/*
 *  @brief 清除硬盘里的图片
 */
+ (void)clearImageFromDisk;
@end
