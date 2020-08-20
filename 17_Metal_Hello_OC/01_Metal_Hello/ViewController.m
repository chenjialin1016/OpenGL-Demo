//
//  ViewController.m
//  01_Metal_Hello
//
//  Created by - on 2020/8/19.
//  Copyright © 2020 -. All rights reserved.
//

#import "ViewController.h"
#import "CJLRenderer.h"

@interface ViewController ()
{
    MTKView *_view;
    CJLRenderer *_render;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    1、获取view（除了在storyboard修改view的类，也可以创建MTKView的对象，添加到view上）
    _view = (MTKView*)self.view;
    
    //2.为_view 设置MTLDevice(必须)，即获得GPU的使用权限
    //一个MTLDevice 对象就代表这着一个GPU,通常我们可以调用方法MTLCreateSystemDefaultDevice()来获取代表默认的GPU单个对象.
    _view.device = MTLCreateSystemDefaultDevice();
    
     //3.判断是否设置成功
    if (!_view.device) {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    //4. 创建CJLRenderer
    //分开你的渲染循环:
    //在我们开发Metal 程序时,将渲染循环分为自己创建的类,是非常有用的一种方式,使用单独的类,我们可以更好管理初始化Metal,以及Metal视图委托.
    _render = [[CJLRenderer alloc] initWithMetalKitView:_view];
    
    //5.判断_render 是否创建成功
    if (!_render) {
        NSLog(@"Renderer failed initialization");
        return;
    }
    
    //6.设置MTKView 的代理(由CJLRender来实现MTKView 的代理方法)
    _view.delegate = _render;
    
    //7.视图可以根据视图属性上设置帧速率(指定时间来调用drawInMTKView方法--视图需要渲染时调用)
    _view.preferredFramesPerSecond = 60;
}


@end
