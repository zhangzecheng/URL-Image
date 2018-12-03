//
//  ZCImageSource.h
//  DemoProdut
//
//  Created by 市民张某 Mackbook Pro on 2018/12/3.
//  Copyright © 2018 abner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,ZCImageSourceType) {
    ZCImageSourceTypeImage,             //静态图片
    ZCImageSourceTypeGIF,               //GIF
};
@interface ZCImageSource : NSObject
@property (nonatomic,strong,readonly) NSString *imageURL;                //图片的链接
@property (nonatomic,strong,readonly) UIImage *image;                    //图片
@property (nonatomic,assign) BOOL isFinish;                              //是否已下载完
@property (nonatomic,assign,readonly) ZCImageSourceType sourceType;      //图片资源类型
/*
 *  @brief 初始化
 *
 *  @param imageURL 图片/GIF的本地链接
 *  @param data     图片/GIF本地data
*/
+ (instancetype)imageSourceWithImageURL:(NSString *)imageURL
                                   data:(NSData *)data;

/*
 *  @brief 初始化
 *
 *  @param imageURL   图片/GIF的网络链接
 *  @param dataLength 图片资源的大小
 */
+ (instancetype)imageSourceWithImageURL:(NSString *)imageURL
                             dataLength:(long long)dataLength;

/*
 *  @brief 更新图片资源的data
 *
 *  @param data 新接收的data
 */
- (void)updateReceiveData:(NSData *)data;

/*
 *  @brief 将图片保存到本地
 */
- (void)saveInLocal:(NSString *)filePath;
@end
