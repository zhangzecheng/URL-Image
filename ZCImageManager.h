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
 *  @brief 查找缓存里的图片/GIF
 *
 *  @param url 资源路径
 *  @param completion 回调
 */
+ (void)searchImageSourceFromMemoryWithURL:(NSString *)url
                                completion:(ZCImageCompletion)completion;

/*
 *  @brief 查找硬盘的图片/GIF
 *
 *  @param url 资源路径
 *  @param completion 回调
 */
+ (void)searchImageSourceFromDiskWithURL:(NSString *)url
                              completion:(ZCImageCompletion)completion;

/*
 *  @brief 下载网络图片/GIF
 *
 *  @param url 资源路径
 *  @param completion 回调
 */
+ (void)downloadImageSource:(NSString *)url
                clompletion:(ZCImageCompletion)completion;

/*
 *  @brief 加载网络图片/GIF,包含了“查找缓存里的图片”、“查找硬盘的图片”、“下载网络图片”三个步骤
 *
 *  @param url 资源路径
 *  @param completion 回调
 */
+ (void)loadImageSource:(NSString *)url
      clompletion:(ZCImageCompletion)completion;

/*
 *  @brieg 加载本地GIF
 *
 *  @param url GIF本地路径
 */
+ (UIImage *)loadLocalGIFWithImageSource:(NSString *)url;
/*
 *  @brief 清除缓存里的图片/GIF
 */
+ (void)clearImageSourceFromMemory;

/*
 *  @brief 清除硬盘里的图片/GIF
 */
+ (void)clearImageSourceFromDisk;
@end
