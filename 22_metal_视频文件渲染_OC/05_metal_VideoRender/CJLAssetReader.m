//
//  CJLAssetReader.m
//  05_metal_VideoRender
//
//  Created by - on 2020/8/29.
//  Copyright © 2020 CJL. All rights reserved.
//

#import "CJLAssetReader.h"

@implementation CJLAssetReader
{
    //轨道
    AVAssetReaderTrackOutput *readerVideoTrackOutput;
    //AVAssetReader可以从原始数据里获取解码后的音视频数据
    AVAssetReader   *assetReader;
    //视频地址
    NSURL *videoUrl;
    //锁
    NSLock *lock;
    
}

//初始化
- (instancetype)initWithUrl:(NSURL *)url{
    
    self = [super init];
    if(self != nil)
    {
        videoUrl = url;
        lock = [[NSLock alloc]init];
        [self setUpAsset];
    }
    return self;
}

//读取Buffer 数据
- (CMSampleBufferRef)readBuffer {
    //锁定
    [lock lock];
    CMSampleBufferRef sampleBufferRef = nil;
    
    //1.判断readerVideoTrackOutput 是否创建成功.
    if (readerVideoTrackOutput) {
       
        //复制下一个缓存区的内容到sampleBufferRef
        sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
    }
    
    //2.判断assetReader 并且status 是已经完成读取 则重新清空readerVideoTrackOutput/assetReader.并重新初始化它们
    if (assetReader && assetReader.status == AVAssetReaderStatusCompleted) {
        NSLog(@"customInit");
        readerVideoTrackOutput = nil;
        assetReader = nil;
        [self setUpAsset];
    }
    
    //取消锁
    [lock unlock];
    
    //3.返回读取到的sampleBufferRef 数据
    return sampleBufferRef;
}


#pragma mark: set up

//Asset 相关设置
-(void)setUpAsset{
   
    //AVURLAssetPreferPreciseDurationAndTimingKey 默认为NO,YES表示提供精确的时长
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    //1. 创建AVURLAsset 是AVAsset 子类,用于从本地/远程URL初始化资源
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:inputOptions];
    
    //2.异步加载资源
    //weakSelf 解决循环引用
    __weak typeof(self) weakSelf = self;
    
    //定义属性名称
    NSString *tracks = @"tracks";
   
    //对资源所需的键执行标准的异步载入操作,这样就可以访问资源的tracks属性时,就不会受到阻碍.
    [inputAsset loadValuesAsynchronouslyForKeys:@[tracks] completionHandler: ^{
        
            //延长self 生命周期
            __strong typeof(self) strongSelf = weakSelf;
       
      //开辟子线程并发队列异步函数来处理读取的inputAsset
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
    
            //获取状态码.
            AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
            //如果状态不等于成功加载,则返回并打印错误信息
            if (tracksStatus != AVKeyValueStatusLoaded)
            {
                NSLog(@"error %@", error);
                return;
            }
            //处理读取的inputAsset
            [weakSelf processWithAsset:inputAsset];
        });
    }];
    
}

//处理获取到的asset
- (void)processWithAsset:(AVAsset *)asset
{
    //锁定
    [lock lock];
    NSLog(@"processWithAsset");
    NSError *error = nil;
    
    //1.创建AVAssetReader
    assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    
    //2.kCVPixelBufferPixelFormatTypeKey 像素格式.
    /*
     kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange : 420v
     kCVPixelFormatType_32BGRA : iOS在内部进行YUV至BGRA格式转换
     */
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    /*3. 设置readerVideoTrackOutput
     assetReaderTrackOutputWithTrack:(AVAssetTrack *)track outputSettings:(nullable NSDictionary<NSString *, id> *)outputSettings
     参数1: 表示读取资源中什么信息
     参数2: 视频参数
     */
    readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    
    //alwaysCopiesSampleData : 表示缓存区的数据输出之前是否会被复制.YES:输出总是从缓存区提供复制的数据,你可以自由的修改这些缓存区数据
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    
    //4.为assetReader 填充输出
    [assetReader addOutput:readerVideoTrackOutput];
    
    //5.assetReader 开始读取.并且判断是否开始.
    if ([assetReader startReading] == NO)
    {
        NSLog(@"Error reading from file at URL: %@", asset);
    }
    
    //取消锁
    [lock unlock];
}

@end
