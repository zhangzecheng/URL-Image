//
//  ZCImageManager.m
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import "ZCImageManager.h"
#import <ImageIO/ImageIO.h>

static NSInteger downloadCount = 0;
@interface ZCImageManager ()
@property (nonatomic,strong) NSString *filePath;                                             //沙盒文件夹的路径
@property (nonatomic,strong) NSMutableDictionary<NSString *,UIImage *> *imageDictM;          //缓存下载完的图片/GIF
@property (nonatomic,strong) NSCache *cache;                                                 //回调队列
@end
@implementation ZCImageManager
#pragma mark - 公有方法
//查找缓存里的图片/GIF
+ (void)searchImageSourceFromMemoryWithURL:(NSString *)url
                          completion:(ZCImageCompletion)completion {
    
    url = [ZCImageManager formattingUrl:url];
    UIImage *image = [ZCImageManager shareInstance].imageDictM[url];
    NSLog(@"下载的图片/GIF%@在memory里",image?@"存":@"不存");
    if(completion)
        completion(image!=nil,image);
}

//查找硬盘的图片/GIF
+ (void)searchImageSourceFromDiskWithURL:(NSString *)url
                        completion:(ZCImageCompletion)completion {
    
    url = [ZCImageManager formattingUrl:url];
    //获取资源路径
    NSString *imagePath = [[ZCImageManager shareInstance].filePath stringByAppendingPathComponent:url];
     BOOL isGIF = [url hasSuffix:@"gif"]||[url hasSuffix:@"GIF"];
    UIImage *image;
    if(isGIF) {
        image = [ZCImageManager loadGIFWithData:[NSData dataWithContentsOfFile:imagePath]];
    }else {
        image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    }
    
    NSLog(@"下载的图片/GIF%@在disk里",image?@"存":@"不存");
    if(completion)
        completion(image!=nil,image);
    
}

//下载网络图片/GIF
+ (void)downloadImageSource:(NSString *)url clompletion:(ZCImageCompletion)completion {
    
    BOOL isGIF = [url hasSuffix:@"gif"]||[url hasSuffix:@"GIF"];
    NSString *blockUrl = [ZCImageManager formattingUrl:url];
    
    void (^operationBlock)(void) = ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        UIImage *image;
        if(isGIF) {
            image = [ZCImageManager loadGIFWithData:data];
        }else {
            image = [ZCImageManager loadImageWithData:data];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
        
            if(image) {
        
                //将下载好的图片储存到缓存和硬盘中
                [[ZCImageManager shareInstance].imageDictM setObject:image forKey:blockUrl];
                [ZCImageManager saveImageSourceToDiskWithURL:blockUrl imageSource:data];
            }
            
            //返回图片
            for(ZCImageCompletion each in [[ZCImageManager shareInstance].cache objectForKey:url]) {
                @autoreleasepool {
                    each(image!=nil,image);
                }
            }
            
            //删除加载这张照片的所有回调
            [[ZCImageManager shareInstance].cache removeObjectForKey:url];
            
            downloadCount = 0;
        });
    };
    
    if(!completion)return;
    
    if(![[ZCImageManager shareInstance].cache objectForKey:url]) {
        
        downloadCount ++;
        //若还没在下载，则加入下载队列，并下载图片
        @autoreleasepool {
            NSMutableArray *arrM = [NSMutableArray array];
            [arrM addObject:completion];
            [[ZCImageManager shareInstance].cache setObject:arrM forKey:url];
        }
        dispatch_async(dispatch_get_global_queue(0, 0), operationBlock);
        NSLog(@"下载的个数:%ld",(long)downloadCount);
    }else {
        
        //若在下载队列里，则将block赋值给这个completion
        @autoreleasepool {
            NSMutableArray *arrM = [[ZCImageManager shareInstance].cache objectForKey:url];
            [arrM addObject:completion];
            [[ZCImageManager shareInstance].cache setObject:arrM forKey:url];
        }
    }
   
}

//加载网络图片/GIF,包含了“查找缓存里的图片”、“查找硬盘的图片”、“下载网络图片”三个步骤
+ (void)loadImageSource:(NSString *)url clompletion:(ZCImageCompletion)completion {
    
    //缓存里找，有则设置图片
    [ZCImageManager searchImageSourceFromMemoryWithURL:url completion:^(BOOL isExist, UIImage *image) {
        if(isExist) {
            if(completion) {
                completion(YES,image);
            }
            return;
        }
        
        //disk 里面找，有则设置图片
        [ZCImageManager searchImageSourceFromDiskWithURL:url completion:^(BOOL isExist, UIImage *image) {
            if(isExist) {
                if(completion) {
                    completion(YES,image);
                }
                return;
            }
            
            //加载网络图片
            [ZCImageManager downloadImageSource:url clompletion:^(BOOL isExist, UIImage *image) {
                if(completion) {
                    completion(isExist,image);
                }
            }];
        }];
    }];
}

//加载本地GIF
+ (UIImage *)loadLocalGIFWithImageSource:(NSString *)url {
    
    NSData *data = [NSData dataWithContentsOfFile:url];
    return [ZCImageManager loadGIFWithData:data];
}

//清除缓存里的图片/GIF
+ (void)clearImageSourceFromMemory {
    [[ZCImageManager shareInstance].imageDictM removeAllObjects];
}

//清除硬盘里的图片/GIF
+ (void)clearImageSourceFromDisk {
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[ZCImageManager shareInstance].filePath
                                               error:&error];
    
    if(error) {
        NSLog(@"\n清除disk里的图片失败,错误原因为:%@",error.userInfo);
    }
}

#pragma mark - 私有方法
//将图片/GIF存到本地
+ (void)saveImageSourceToDiskWithURL:(NSString *)url imageSource:(NSData *)imageSource {
    
    NSString *imagePath = [[ZCImageManager shareInstance].filePath stringByAppendingPathComponent:url];
    
    BOOL result = [imageSource writeToFile:imagePath atomically:YES];
    
    NSLog(@"图片保存%@",result?@"成功":@"失败");

}

//格式化url
+ (NSString *)formattingUrl:(NSString *)url {
    
    return [[url componentsSeparatedByString:@"/"] componentsJoinedByString:@"_"];
}

//通过NSData加载GIF
+ (UIImage *)loadGIFWithData:(NSData *)data {
    
    if(!data) return nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(imageSource);
    NSMutableArray *imagesArrM = [NSMutableArray array];
    NSTimeInterval duration = 0;
    for (size_t i = 0; i < count; i++) {
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
        if (!imageRef) continue;
        duration += [ZCImageManager durationAtIndex:imageSource index:i];
        [imagesArrM addObject:[UIImage imageWithCGImage:imageRef]];
        CGImageRelease(imageRef);
    }
    
    if (!duration) duration = 0.1 * count;
    CFRelease(imageSource);
    
    return [UIImage animatedImageWithImages:imagesArrM duration:duration];
}

//通过NSData加载图片
+ (UIImage *)loadImageWithData:(NSData *)data {
    
    return [UIImage imageWithData:data];
}

//获取每一帧的时间
+ (CGFloat)durationAtIndex:(CGImageSourceRef)source index:(NSInteger)index {
    
    float duration = 0.1f;
    CFDictionaryRef propertiesRef = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *properties = (__bridge NSDictionary *)propertiesRef;
    NSDictionary *gifProperties = properties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTime) duration = delayTime.floatValue;
    else {
        delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime) duration = delayTime.floatValue;
    }
    CFRelease(propertiesRef);
    return duration;
}

#pragma mark - 生命周期
+ (instancetype)shareInstance {
    
    static ZCImageManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ZCImageManager alloc] init];
    });
    return manager;
}

#pragma mark - setters and getters
- (NSMutableDictionary *)imageDictM {
    
    if(!_imageDictM) {
        _imageDictM = [NSMutableDictionary dictionary];
    }
    return _imageDictM;
}

- (NSCache *)cache {
    
    if(!_cache) {
        _cache = [[NSCache alloc] init];
    }
    
    return _cache;
}


- (NSString *)filePath {
    if(!_filePath) {
        /*
         1.第一个参数；存在documents文件里
         2.第二个参数：文件的检索范围只在沙盒内部
         3.第三个参数：展开完整路径
         */
        //disk路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if(paths.count==0) return @"";
        
        //文件夹路径
       _filePath = [paths.firstObject stringByAppendingPathComponent:NSStringFromClass([ZCImageManager class])];
        NSLog(@"\n文件夹的路径:%@",_filePath);
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
            //文件夹不存在
            [[NSFileManager defaultManager] createDirectoryAtPath:_filePath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
            
        }

    }
    
    return _filePath;
    
}

@end
