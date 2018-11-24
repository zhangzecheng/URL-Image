//
//  MHImageManager.m
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import "MHImageManager.h"
@interface MHImageManager ()
@property (nonatomic,strong) NSString *filePath;                                         //沙盒文件夹的路径
@property (nonatomic,strong) NSMutableDictionary<NSString *,UIImage *> *imageDictM;      //缓存下载完的图片
@property (nonatomic,strong) NSMutableDictionary<NSString *, NSMutableArray *> *operationDictM;                        //回调队列
@end
@implementation MHImageManager
#pragma mark - 公有方法
+ (void)searchImageFromMemoryWithURL:(NSString *)url
                          completion:(MHImageCompletion)completion {
    
    url = [MHImageManager formattingUrl:url];
    UIImage *image = [MHImageManager shareInstance].imageDictM[url];
    NSLog(@"下载的图片%@在memory里",image?@"存":@"不存");
    if(completion)
        completion(image != nil,image);
}

+ (void)searchImageFromDiskWithURL:(NSString *)url
                        completion:(MHImageCompletion)completion {
    
    url = [MHImageManager formattingUrl:url];
    //获取图片路径
    NSString *imagePath = [[MHImageManager shareInstance].filePath stringByAppendingPathComponent:url];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
     NSLog(@"下载的图片%@在disk里",image?@"存":@"不存");
    if(completion)
        completion(image != nil , image);
    
}

+ (void)loadImage:(NSString *)url clompletion:(MHImageCompletion)completion {
    
    void (^operationBlock)(void);
    
    //弱引用，避免循环引用
    void (^__block weakOperationBlock)(void) = operationBlock;
    __block NSString *blockUrl = url;
    
    operationBlock = ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        UIImage *image = [UIImage imageWithData:data];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if(image) {
                
                blockUrl = [MHImageManager formattingUrl:url];
                
                //将下载好的图片储存到缓存和硬盘中
                [[MHImageManager shareInstance].imageDictM setObject:image forKey:blockUrl];
                [MHImageManager saveImageToDiskWithURL:blockUrl image:image];
            }
            
            //返回图片
            for(MHImageCompletion each in [MHImageManager shareInstance].operationDictM[url]) {
                @autoreleasepool {
                    each(image,image);
                }
            }
            
            //删除加载这张照片的所有回调
            [[MHImageManager shareInstance].operationDictM removeObjectForKey:url];
        });
    };
    
    weakOperationBlock = operationBlock;
    
    if(!completion)return;
    
    if(![MHImageManager shareInstance].operationDictM[url]) {
        
        //若还没在下载，则加入下载队列，并下载图片
        NSMutableArray *arrM = [NSMutableArray array];
        [arrM addObject:completion];
        [[MHImageManager shareInstance].operationDictM setObject:arrM forKey:url];
        dispatch_async(dispatch_get_global_queue(0, 0), operationBlock);
    }else {
        
        //若在下载队列里，则将block赋值给这个completion
        NSMutableArray *arrM = [MHImageManager shareInstance].operationDictM[url];
        [arrM addObject:completion];
        [[MHImageManager shareInstance].operationDictM setObject:arrM forKey:url];
        
    }
   
    NSLog(@"下载的操作队列个数:%lu",(unsigned long)[MHImageManager shareInstance].operationDictM.allKeys.count);
}

+ (void)clearImageFromMemory {
    [[MHImageManager shareInstance].imageDictM removeAllObjects];
}

+ (void)clearImageFromDisk {
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:[MHImageManager shareInstance].filePath
                                               error:&error];
    
    if(error) {
        NSLog(@"\n清除disk里的图片失败,错误原因为:%@",error.userInfo);
    }
}

#pragma mark - 私有方法
+ (void)saveImageToDiskWithURL:(NSString *)url image:(UIImage *)image {
    
    NSString *imagePath = [[MHImageManager shareInstance].filePath stringByAppendingPathComponent:url];
    
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
    static MHImageManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MHImageManager alloc] init];
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

- (NSMutableDictionary *)operationDictM {
    
    if(!_operationDictM) {
        _operationDictM = [NSMutableDictionary dictionary];
    }
    return _operationDictM;
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
       _filePath = [paths.firstObject stringByAppendingPathComponent:NSStringFromClass([MHImageManager class])];
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
