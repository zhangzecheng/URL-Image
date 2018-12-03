//
//  ZCImageSource.m
//  DemoProdut
//
//  Created by 市民张某 Mackbook Pro on 2018/12/3.
//  Copyright © 2018 abner. All rights reserved.
//

#import "ZCImageSource.h"
@interface ZCImageSource ()
@property (nonatomic,strong) NSMutableData *receiveData;        //接收的图片数据
@property (nonatomic,assign) CGImageSourceRef imageSourceRef;
@property (nonatomic,assign) long long dataLength;              //数据长度
@property (nonatomic,assign) BOOL isGIF;                        //是否为GIF
@end
@implementation ZCImageSource
#pragma mark - 生命周期
+ (instancetype)imageSourceWithImageURL:(NSString *)imageURL
                                   data:(NSData *)data {
    
    ZCImageSource *imageSource = [[ZCImageSource alloc] initWithImageURL:imageURL
                                                                    data:data];
    return imageSource;
}

+ (instancetype)imageSourceWithImageURL:(NSString *)imageURL
                             dataLength:(long long)dataLength {
    
    ZCImageSource *imageSource = [[ZCImageSource alloc] initWithImageURL:imageURL
                                                              dataLength:dataLength];
    return imageSource;
}

- (instancetype)initWithImageURL:(NSString *)imageURL
                      dataLength:(long long)dataLength {
    
    if(self = [super init]) {
        self.receiveData = [NSMutableData data];
        self.imageSourceRef = CGImageSourceCreateIncremental(NULL);
        self.dataLength = dataLength;
        _imageURL = imageURL;
        self.isGIF = ([_imageURL hasSuffix:@"gif"]||[_imageURL hasSuffix:@"GIF"]);
    }
    return self;
}

- (instancetype)initWithImageURL:(NSString *)imageURL
                            data:(NSData *)data {
    
    if(self = [super init]) {
        self.receiveData = [NSMutableData dataWithData:data];
        self.imageSourceRef = CGImageSourceCreateIncremental(NULL);
        self.dataLength = data.length;
        _imageURL = imageURL;
        self.isGIF = ([_imageURL hasSuffix:@"gif"]||[_imageURL hasSuffix:@"GIF"]);
    }
    return self;
}

#pragma mark - 公有方法
//更新图片资源的data
- (void)updateReceiveData:(NSData *)data {
    
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        [self.receiveData appendBytes:bytes length:byteRange.length];
    }];
   
    CGImageSourceUpdateData(self.imageSourceRef, (CFDataRef)self.receiveData, self.isFinish);
}

- (void)saveInLocal:(NSString *)filePath {
    
    BOOL result = [[NSData dataWithData:self.receiveData] writeToFile:filePath atomically:YES];
    NSLog(@"图片保存%@",result?@"成功":@"失败");
}
#pragma mark - 私有方法
//通过data加载UIImage
- (UIImage *)loadImage {
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(self.imageSourceRef, 0, NULL);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

//通过data加载GIF
- (UIImage *)loadGIF {
    
    if(!self.receiveData) return nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.receiveData, NULL);
    size_t count = CGImageSourceGetCount(imageSource);
    NSMutableArray *imagesArrM = [NSMutableArray array];
    NSTimeInterval duration = 0;
    for (size_t i = 0; i < count; i++) {
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
        if (!imageRef) continue;
        duration += [self durationAtIndex:imageSource index:i];
        [imagesArrM addObject:[UIImage imageWithCGImage:imageRef]];
        CGImageRelease(imageRef);
    }
    
    if (!duration) duration = 0.1 * count;
    CFRelease(imageSource);
    
    return [UIImage animatedImageWithImages:imagesArrM duration:duration];
}

//每一帧的时间
- (CGFloat)durationAtIndex:(CGImageSourceRef)source index:(NSInteger)index {
    
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

#pragma mark - setters and getters
- (UIImage *)image {
    
    if(self.isGIF) {
        return [self loadGIF];
    }
    
    return [self loadImage];
}

- (BOOL)isFinish {
    
    return (self.receiveData.length == self.dataLength);
}

- (ZCImageSourceType)sourceType {
    
    return self.isGIF?ZCImageSourceTypeGIF:ZCImageSourceTypeImage;
}
@end
