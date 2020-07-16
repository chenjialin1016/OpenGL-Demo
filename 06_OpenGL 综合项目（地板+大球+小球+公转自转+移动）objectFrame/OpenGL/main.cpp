#include "GLTools.h"
#include "GLShaderManager.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLMatrixStack.h"
#include "GLGeometryTransform.h"
#include "StopWatch.h"

#include <math.h>
#include <stdio.h>

#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif


//使用GLFrustum类来设置透视投影
GLFrustum           viewFrustum;
GLMatrixStack       modelViewMatix;
GLMatrixStack       projectionMatrix;
GLGeometryTransform transformPipeline;
GLShaderManager     shaderManager;

////设置角色帧，作为相机
GLFrame             viewFrame;
GLFrame             cameraFrame;

//大球 --- 红色
GLTriangleBatch     torusBatch;
//小球 --- 随机静态蓝色，自转小球
GLTriangleBatch     sphereBatch;
//地板
GLBatch     floorBatch;

//添加附加随机球
#define NUM_SPHERE 50
GLFrame sphere[NUM_SPHERE];




void SetupRC()
{
    
    //1、初始化
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    shaderManager.InitializeStockShaders();
    
    //    为什么加这句就可以修正初始位置？----修正了原始矩阵为（0，0，5.0）,变为大球的正前方
    viewFrame.MoveForward(10.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    //2、地板顶点数据
    floorBatch.Begin(GL_LINES, 324);
    for (GLfloat x = -20.0f; x <= 20.0f; x += 0.5) {
        floorBatch.Vertex3f(x, -0.55f, 20.0f);
        floorBatch.Vertex3f(x, -0.55f, -20.0f);
        
        floorBatch.Vertex3f(20.0f, -0.55f, x);
        floorBatch.Vertex3f(-20.0f, -0.55f, x);
    }
    floorBatch.End();
    

    
    //4、大球数据（大球和动态小球都默认在0.0位置，需要偏移一下）
    gltMakeSphere(torusBatch, 0.4f, 40, 80);
    
    //5、小球数据
    //小球分两种：静态50个，动态1个
    gltMakeSphere(sphereBatch, 0.1f, 26, 13);
    for (int i = 0; i < NUM_SPHERE; i++) {
        //在一个平面上，Y轴值都是相等的
        GLfloat x = (GLfloat)(((rand()%400)-200 )*0.1f);
        GLfloat z = (GLfloat)(((rand()%400)-200 )*0.1f);
        
        sphere[i].SetOrigin(x, 0.0f, z);
    }
    
    
    
}

//渲染场景
void RenderScene()
{
    //设置颜色及清理缓存
    static GLfloat vFloorColor[] = {0.0f, 1.0f, 0.0f, 1.0f};
    static GLfloat vTorusColor[] = {1.0f, 0.0f, 0.0f, 1.0f};
    static GLfloat vSphereColor[] = {0.0f, 0.0f, 1.0f, 1.0f};
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //时间动画
    static CStopWatch rotTimer;
    //得到一个旋转的度数
    float yRot = rotTimer.GetElapsedSeconds()*60.0f;
    
    
     //发生移动
        /*
         1、物体移动：两种方式 一个个移动 + objectFrame
         2、移动观察者
         */
        //加入观察者--应该是用于所有
    //矩阵堆栈：单元矩阵*观察者矩阵 = 观察者矩阵
    //    M3DMatrix44f mCamera;
    //    cameraFrame.GetCameraMatrix(mCamera);
    //    modelViewMatix.PushMatrix(mCamera); //在画完 5、动态小球之后pop
        
    //    首次出现位置有问题--需要在setupRC中设置下viewFrame位置
        modelViewMatix.PushMatrix(viewFrame);
    
    //2、地板绘制
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vFloorColor);
    floorBatch.Draw();
    
   
    
    
    //3、大球（红色）自转
    //光源位置 -- 底层是四维计算
    M3DVector4f vlightPos = {0.0f, 10.0f, 5.0f, 1.0f};
    //球移动 1）观察者camera改变 2）objectFrame 3）物体本身平移（本次使用）
    //1-2都只是一个中间变量，用来记录变化矩阵
    // 2-3都是物体本身移动，区别是2中使用了中间变量
    //让物体平移 -- z轴平移-3.0像素点（往屏幕里面是负，往屏幕外面是正）
//    疑问：为什么是先平移在复制？-----因为只需要平移一次，如果是先push在平移，就是旋转一次平移一次，并不是我们想要的结果
//    所有的矩阵都是记录变化：单元矩阵 --> 平移 --> 平移矩阵
//矩阵堆栈：观察者矩阵  --> 观察者平移矩阵
    modelViewMatix.Translate(0.0f, 0.0f, -3.0f);
    //将平移的矩阵结果，copy一份到栈顶，目的是为了自转小球的结果不影响平移的结果
//矩阵堆栈：观察者矩阵  --> 观察者平移矩阵  --> 观察者平移矩阵
    modelViewMatix.PushMatrix();
    //小球围绕y轴自转
//矩阵堆栈：观察者矩阵  --> 观察者平移矩阵  --> 观察者平移矩阵*旋转矩阵 = 观察平移旋转矩阵
    modelViewMatix.Rotate(yRot, 0, 1, 0);
    
    //绘制大球
    shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vlightPos, vTorusColor);
    torusBatch.Draw();
    
    //    有几个push，就有几个pop
//矩阵堆栈：观察者矩阵  --> 观察者平移矩阵
    modelViewMatix.PopMatrix();
    
    
    //4、 画小球
    //静态小球
    for(int i = 0; i < NUM_SPHERE; i++) {
        //此时push的是平移矩阵
//矩阵堆栈：观察者矩阵  --> 观察者平移矩阵 -->  观察者平移矩阵
        modelViewMatix.PushMatrix();
        modelViewMatix.MultMatrix(sphere[i]);
        shaderManager.UseStockShader(GLT_SHADER_POINT_LIGHT_DIFF, transformPipeline.GetModelViewMatrix(),
        transformPipeline.GetProjectionMatrix(), vlightPos, vSphereColor);
        sphereBatch.Draw();
        //画一个小球push-pop一下
//矩阵堆栈：观察者矩阵  --> 观察者平移矩阵
        modelViewMatix.PopMatrix();
    }
    
    //5、动态小球--蓝色的公转
//矩阵堆栈：观察者矩阵  --> 观察者平移矩阵*旋转 = 观察者平移旋转矩阵
    modelViewMatix.Rotate(yRot*-2.0f, 0.0f, 1, 0.0f);
    //让动态小球沿x轴移动一下（往里是正，往外是负）
//    原因：大球和动态小球只设置了大小，没有设置位置，所以都处于原点，需要移动下动态小球
    modelViewMatix.Translate(1.0f, 0.0f, 0.0f);
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vSphereColor);
    sphereBatch.Draw();
    
//矩阵堆栈：观察者矩阵
    modelViewMatix.PopMatrix();
    

    
    glutSwapBuffers();
    
    //不断渲染
    glutPostRedisplay();
}

//键位设置，通过不同的键位对其进行设置
//控制Camera的移动，从而改变视口
void SpecialKeys(int key, int x, int y)
{
    //步长
    float linear = 0.1f;
    //旋转度数
    float angular = float(m3dDegToRad(5.0f));
    
//    此时的up、down相当于前后，MoveForward默认是-z方向，所以up时MoveForward传的是正数
    if (key == GLUT_KEY_UP) {
        //平移--观察者角度，物体对面，所以是正的
//        cameraFrame.MoveForward(linear);
        viewFrame.MoveForward(-linear);
    }
    
    if (key == GLUT_KEY_DOWN) {
//        cameraFrame.MoveForward(-linear);
        viewFrame.MoveForward(linear);
    }
    
    if (key == GLUT_KEY_LEFT) {
//        cameraFrame.RotateWorld(angular, 0.0f, 1.0f, 0.0f);
        viewFrame.RotateWorld(angular, 0.0f, 1.0f, 0.0f);
    }
    
    if (key == GLUT_KEY_RIGHT) {
//        cameraFrame.RotateWorld(-angular, 0.0f, 1.0f, 0.0f);
        viewFrame.RotateWorld(-angular, 0.0f, 1.0f, 0.0f);
    }
}

//窗口改变
void ChangeSize(int w, int h)
{
    //视口
    glViewport(0, 0, w, h);
    
    //设置投影
    viewFrustum.SetPerspective(35.0f, floor(w)/floor(h), 1.0, 100);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
    //设置变换管道
    transformPipeline.SetMatrixStacks(modelViewMatix, projectionMatrix);
}



int main(int argc, char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_STENCIL);
    glutInitWindowSize(800, 600);
    glutCreateWindow("Geometry Test Program");
    glutReshapeFunc(ChangeSize);
    glutSpecialFunc(SpecialKeys);
    glutDisplayFunc(RenderScene);
    
    GLenum err = glewInit();
    if (GLEW_OK != err) {
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    SetupRC();
    
    glutMainLoop();
    return 0;
}
