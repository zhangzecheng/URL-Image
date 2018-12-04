//
//  ZCImageManager.m
//  DemoTestProduct
//
//  Created by 市民张某 Mackbook Pro on 2018/11/24.
//  Copyright © 2018 XB. All rights reserved.
//

#import "ZCImageManager.h"
#import <ImageIO/ImageIO.h>
#import "ZCImageSource.h"

@interface ZCImageManager () <
NSURLSessionDelegate
>

@property (nonatomic,strong) NSString *filePath;                                                                     //沙盒文件夹的路径
@property (nonatomic,strong) NSMutableDictionary<NSString *,NSMutableArray<ZCImageCompletion> *> *callBackDict;      //回调
@property (nonatomic,strong) NSMutableDictionary<NSString *,ZCImageSource *> *downloadDict;                          //下载队列
@property (nonatomic,strong) NSCache<NSString *,ZCImageSource *> *cache;                                             //已下载的图片/GIF的缓存
@property (nonatomic,assign) BOOL isShowLoadingAnimation;                                                            //是否边下边显示
@property (nonatomic,strong) NSURLSession *session;                                                                  //下载
@end
@implementation ZCImageManager
#pragma mark - 公有方法
//查找缓存里的图片/GIF
+ (void)searchImageSourceFromMemoryWithURL:(NSString *)url
                          completion:(ZCImageCompletion)completion {
    
    ZCImageSource *imageSource = [[ZCImageManager shareInstance].cache objectForKey:url];
    UIImage *image = imageSource.image;
    if(image)
        NSLog(@"下载的图片/GIF存在memory里");
    if(completion)
        completion(image!=nil,image);
}

//查找硬盘的图片/GIF
+ (void)searchImageSourceFromDiskWithURL:(NSString *)url
                        completion:(ZCImageCompletion)completion {
    
    NSString *formatURL = [ZCImageManager formattingUrl:url];
    //获取资源路径
    NSString *imagePath = [[ZCImageManager shareInstance].filePath stringByAppendingPathComponent:formatURL];
    ZCImageSource *imageSource = [ZCImageSource imageSourceWithImageURL:url
                                                                   data:[NSData dataWithContentsOfFile:imagePath]];
    UIImage *image = imageSource.image;
    if(image)
        NSLog(@"下载的图片/GIF存在disk里");
    if(completion)
        completion(image!=nil,image);
    
}

//下载网络图片/GIF
+ (void)downloadImageSource:(NSString *)url clompletion:(ZCImageCompletion)completion {
    
    //将回调存入回调字典中
    @autoreleasepool {
        NSMutableArray *arrM = [[ZCImageManager shareInstance].callBackDict objectForKey:url];
        if(arrM.count==0)
            arrM = [NSMutableArray array];
        
        if(completion) {
            [arrM addObject:completion];
            [[ZCImageManager shareInstance].callBackDict setObject:arrM forKey:url];
        }
    }
    
    //判断是否在下载，是则将回调加入
    if([[ZCImageManager shareInstance].downloadDict objectForKey:url]) {
        NSLog(@"已经在下载");
        return;
    }
    
    NSLog(@"开始下载");
    @autoreleasepool {
        ZCImageSource *imageSource = [ZCImageSource imageSourceWithImageURL:url
                                                                 dataLength:0];
        [[ZCImageManager shareInstance].downloadDict setObject:imageSource
                                                        forKey:url];
        //否则开始下载
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLSessionTask *task = [[ZCImageManager shareInstance].session dataTaskWithRequest:urlRequest];
        [task resume];
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
//
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
    ZCImageSource *imageSource = [ZCImageSource imageSourceWithImageURL:url
                                                                   data:data];
    return imageSource.image;
}

//清除缓存里的图片/GIF
+ (void)clearImageSourceFromMemory {
    
    [[ZCImageManager shareInstance].cache removeAllObjects];
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

+ (void)setShowLoadingAnimation:(BOOL)flag {
    
    [ZCImageManager shareInstance].isShowLoadingAnimation = flag;
}

#pragma mark - 私有方法
//格式化url
+ (NSString *)formattingUrl:(NSString *)url {
    
    NSString *newURL = [[url componentsSeparatedByString:@":"] componentsJoinedByString:@""];
    return [[newURL componentsSeparatedByString:@"/"] componentsJoinedByString:@"_"];
}

- (void)handleAllCallBack:(NSString *)imageURL image:(UIImage *)image {
    
    NSMutableArray *arrM = [[ZCImageManager shareInstance].callBackDict objectForKey:imageURL];
    for(ZCImageCompletion completion in arrM) {
        @autoreleasepool {
            completion(image!=nil,image);
        }
    }
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

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
    @autoreleasepool {
        NSString *imageURL = response.URL.absoluteString;
        ZCImageSource *imageSource = [ZCImageSource imageSourceWithImageURL:imageURL
                                                                 dataLength:response.expectedContentLength];
        [[ZCImageManager shareInstance].downloadDict setObject:imageSource
                                                        forKey:imageURL];
    }
    
    
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    
    NSString *imageURL = dataTask.response.URL.absoluteString;
    NSString *formatURL = [ZCImageManager formattingUrl:imageURL];
    ZCImageSource *imageSource = [[ZCImageManager shareInstance].downloadDict objectForKey:imageURL];
    [imageSource updateReceiveData:data];
    UIImage *image = imageSource.image;

    //是否边下边显示
    if([ZCImageManager shareInstance].isShowLoadingAnimation&&
       imageSource.sourceType == ZCImageSourceTypeImage) {
        
        [self handleAllCallBack:imageURL image:image];
    }
    if(imageSource.isFinish) {
        
        //将下载好的图片储存到缓存和硬盘中
        [[ZCImageManager shareInstance].cache setObject:imageSource
                                                 forKey:imageURL];
        [imageSource saveInLocal:[[ZCImageManager shareInstance].filePath stringByAppendingPathComponent:formatURL]];
        
        //返回图片
        [self handleAllCallBack:imageURL image:image];
        
        //删除加载这张照片的所有回调
        [[ZCImageManager shareInstance].callBackDict removeObjectForKey:imageURL];
        [[ZCImageManager shareInstance].downloadDict removeObjectForKey:imageURL];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    
    NSLog(@"加载失败:%@",error.userInfo);
}

#pragma mark - setters and getters
- (NSMutableDictionary<NSString *,NSMutableArray<ZCImageCompletion> *> *)callBackDict {
    
    if(!_callBackDict) {
        _callBackDict = [NSMutableDictionary dictionary];
    }
    return _callBackDict;
}

- (NSMutableDictionary<NSString *,ZCImageSource *> *)downloadDict {
    
    if(!_downloadDict) {
        _downloadDict = [NSMutableDictionary dictionary];
    }
    return _downloadDict;
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

- (NSURLSession *)session {
    
    if(!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:[NSOperationQueue mainQueue]];
    }
    
    return _session;
}
@end
