//
//  ZCImageManager.m
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import "ZCImageManager.h"
@interface ZCImageManager ()
@property (nonatomic,strong) NSString *filePath;                                             //沙盒文件夹的路径
@property (nonatomic,strong) NSMutableDictionary<NSString *,UIImage *> *imageDictM;          //缓存下载完的图片
@property (nonatomic,strong) NSCache *cache;                                                 //回调队列
@end
@implementation ZCImageManager
#pragma mark - 公有方法
+ (void)searchImageFromMemoryWithURL:(NSString *)url
                          completion:(ZCImageCompletion)completion {
    
    UIImage *image = [ZCImageManager shareInstance].imageDictM[url];
    NSLog(@"下载的图片%@在memory里",image?@"存":@"不存");
    if(completion)
        completion(image,image);
}

+ (void)searchImageFromDiskWithURL:(NSString *)url
                        completion:(ZCImageCompletion)completion {
    
    //获取图片路径
    NSString *imagePath = [[ZCImageManager shareInstance].filePath stringByAppendingPathComponent:url];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
     NSLog(@"下载的图片%@在disk里",image?@"存":@"不存");
    if(completion)
        completion(image, image);
    
}

+ (void)loadImage:(NSString *)url clompletion:(ZCImageCompletion)completion {
    
    __block NSString *blockUrl = url;
    void (^operationBlock)(void) = ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        UIImage *image = [UIImage imageWithData:data];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if(image) {
                
                blockUrl = [ZCImageManager formattingUrl:url];
                
                //将下载好的图片储存到缓存和硬盘中
                [[ZCImageManager shareInstance].imageDictM setObject:image forKey:url];
                [ZCImageManager saveImageToDiskWithURL:blockUrl image:image];
            }
            
            //返回图片
            for(ZCImageCompletion each in [[ZCImageManager shareInstance].cache objectForKey:url]) {
                @autoreleasepool {
                    each(image,image);
                }
            }
            
            //删除加载这张照片的所有回调
            [[ZCImageManager shareInstance].cache removeObjectForKey:url];
        });
    };
    
    if(!completion)return;
    
    if(![[ZCImageManager shareInstance].cache objectForKey:url]) {
        
        //若还没在下载，则加入下载队列，并下载图片
        @autoreleasepool {
            NSMutableArray *arrM = [NSMutableArray array];
            [arrM addObject:completion];
            [[ZCImageManager shareInstance].cache setObject:arrM forKey:url];
        }
        dispatch_async(dispatch_get_global_queue(0, 0), operationBlock);
    }else {
        
        //若在下载队列里，则将block赋值给这个completion
        @autoreleasepool {
            NSMutableArray *arrM = [[ZCImageManager shareInstance].cache objectForKey:url];
            [arrM addObject:completion];
            [[ZCImageManager shareInstance].cache setObject:arrM forKey:url];
        }
    }
   
}

+ (void)clearImageFromMemory {
    [[ZCImageManager shareInstance].imageDictM removeAllObjects];
}

+ (void)clearImageFromDisk {
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[ZCImageManager shareInstance].filePath
                                               error:&error];
    
    if(error) {
        NSLog(@"\n清除disk里的图片失败,错误原因为:%@",error.userInfo);
    }
}

#pragma mark - 私有方法
+ (void)saveImageToDiskWithURL:(NSString *)url image:(UIImage *)image {
    
    NSString *imagePath = [[ZCImageManager shareInstance].filePath stringByAppendingPathComponent:url];
    
    BOOL result;
    if([imagePath hasSuffix:@"png"])
       result = [UIImagePNGRepresentation(image) writeToFile:imagePath atomically:YES];
    else
       result = [UIImageJPEGRepresentation(image, 0) writeToFile:imagePath atomically:YES];
    
    NSLog(@"图片保存%@",result?@"成功":@"失败");
}

+ (NSString *)formattingUrl:(NSString *)url {
    
    return [[url componentsSeparatedByString:@"/"] componentsJoinedByString:@"_"];
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
