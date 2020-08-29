//
//  CJLAssetReader.h
//  05_metal_VideoRender
//
//  Created by - on 2020/8/29.
//  Copyright © 2020 CJL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJLAssetReader : NSObject

//初始化
- (instancetype)initWithUrl:(NSURL *)url;

//从mov/mp4文件读取CMSampleBufferRef数据
// 视频渲染样本：CMSampleBufferRef（未压缩前 或 解压缩后 的数据）
- (CMSampleBufferRef)readBuffer;

@end

NS_ASSUME_NONNULL_END
