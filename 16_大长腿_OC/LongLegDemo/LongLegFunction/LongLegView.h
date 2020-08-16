//
//  LongLegView.h
//  001--CClhDemo
//
//  Created by CC老师 on 2020/6/22.
//  Copyright © 2020年 CC老师. All rights reserved.
//

#import <GLKit/GLKit.h>
@class LongLegView;

@protocol LongLegViewViewDelegate <NSObject>

//代理方法(SpringView拉伸区域修改)
- (void)springViewStretchAreaDidChanged:(LongLegView *)springView;

@end


@interface LongLegView : GLKView
@property (nonatomic, weak) id <LongLegViewViewDelegate> springDelegate;
@property (nonatomic, assign, readonly) BOOL hasChange; // 拉伸区域是否被拉伸

/**
 将区域拉伸或压缩为某个高度
 @param startY 开始的纵坐标位置（相对于纹理）
 @param endY 结束的纵坐标位置（相对于纹理）
 @param newHeight 新的高度（相对于纹理）
 */
- (void)stretchingFromStartY:(CGFloat)startY
                      toEndY:(CGFloat)endY
               withNewHeight:(CGFloat)newHeight;

/**
 纹理顶部的纵坐标 0～1
 
 @return 纹理顶部的纵坐标（相对于 View）
 */
- (CGFloat)textureTopY;

/**
 纹理底部的纵坐标 0～1
 
 @return 纹理底部的纵坐标（相对于 View）
 */
- (CGFloat)textureBottomY;

/**
 可伸缩区域顶部的纵坐标 0～1
 
 @return 可伸缩区域顶部的纵坐标（相对于 View）
 */
- (CGFloat)stretchAreaTopY;

/**
 可伸缩区域底部的纵坐标 0～1
 
 @return 可伸缩区域底部的纵坐标（相对于 View）
 */
- (CGFloat)stretchAreaBottomY;

/**
 纹理高度 0～1
 
 @return 纹理高度（相对于 View）
 */
- (CGFloat)textureHeight;

/**
 获取当前的渲染结果
 */
- (UIImage *)createResult;

/**
 根据当前的拉伸结果来重新生成纹理
 */
- (void)updateTexture;

/**
 更新图片
 */
- (void)updateImage:(UIImage *)image;

@end
