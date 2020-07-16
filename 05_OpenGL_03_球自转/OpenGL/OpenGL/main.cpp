// Objects.cpp
// OpenGL SuperBible, Chapter 4
// Demonstrates GLTools built-in objects
// Program by Richard S. Wright Jr.

#include "GLTools.h"    // OpenGL toolkit
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLGeometryTransform.h"
#include "StopWatch.h"

#include <math.h>
#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif


GLShaderManager        shaderManager;
GLMatrixStack        modelViewMatrix;
GLMatrixStack        projectionMatrix;
//观察者位置
GLFrame                cameraFrame;
//世界坐标位置
GLFrame             objectFrame;

//视景体，用来构造投影矩阵
GLFrustum            viewFrustum;

//三角形批次类
GLTriangleBatch     CC_Triangle;

//球
GLTriangleBatch     sphereBatch;
//环
GLTriangleBatch     torusBatch;
//圆柱
GLTriangleBatch     cylinderBatch;
//锥
GLTriangleBatch     coneBatch;
//磁盘
GLTriangleBatch     diskBatch;

GLGeometryTransform    transformPipeline;
M3DMatrix44f        shadowMatrix;

GLfloat vGreen[] = { 0.5f, 0.7f, 0.7f, 1.0f };
GLfloat vBlack[] = { 0.0f, 0.0f, 0.0f, 1.0f };

int nStep = 0;

// 将上下文中，进行必要的初始化
void SetupRC()
{
    //1.
    glClearColor(0.7f, 0.7f, 0.7f, 1.0f );
    shaderManager.InitializeStockShaders();
    glEnable(GL_DEPTH_TEST);

    //2、
    gltMakeSphere(sphereBatch, 0.4f, 10, 30);
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    
    
    
}



void DrawWireFramedBatch(GLTriangleBatch* pBatch)
{
    //1、绘制图形
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vGreen);
    pBatch->Draw();
    
    //2、画黑色边框
    //多边形偏移
    glEnable(GL_POLYGON_OFFSET_LINE);
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    glPolygonOffset(-1.0f, -1.0f);
    glLineWidth(2.5f);
    
    //3、开启混合功能(颜色混合&抗锯齿功能)，并不能完全的抗锯齿
    glEnable(GL_BLEND);
    glEnable(GL_LINE_SMOOTH);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    
    //4、画线
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vBlack);
    pBatch->Draw();
    
    //5、恢复多边形模式和深度测试
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    glDisable(GL_POLYGON_OFFSET_LINE);
    glLineWidth(1.0f);
    glDisable(GL_BLEND);
    glDisable(GL_LINE_SMOOTH);
    
}

//召唤场景
void RenderScene(void)
{
   
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //1、基于时间变化 CStopWatch--NSTimer定时器
    static CStopWatch rotTimer;
    //获得角度
    float yRot = rotTimer.GetElapsedSeconds() * 60.0f;
    
    //3、创建3矩阵: 平移、旋转、模型视图矩阵、模型视图投影
    M3DMatrix44f mTranslate, mRotate, mModelView, mModelViewProjection;
    
    //往z轴移动-2.5f
    m3dTranslationMatrix44(mTranslate, 0, 0, -2.5f);
    //围绕y轴旋转
    m3dRotationMatrix44(mRotate, m3dDegToRad(yRot), 0, 1, 0);
    
    //矩阵相乘
    m3dMatrixMultiply44(mModelView, mTranslate, mRotate);
    //mvp是有顺序的：结果-p-mv，不满足交换律
    m3dMatrixMultiply44(mModelViewProjection, viewFrustum.GetProjectionMatrix(), mModelView);
    
    GLfloat vBlack[] = {0,0,0,1};
    shaderManager.UseStockShader(GLT_SHADER_FLAT, mModelViewProjection, vBlack);
    
    sphereBatch.Draw();
    glutSwapBuffers();
    glutPostRedisplay();
}




//上下左右，移动图形
void SpecialKeys(int key, int x, int y)
{
    if(key == GLUT_KEY_UP)
        //移动世界坐标系，而不是去移动物体。
        //将世界坐标系在X方向移动-5.0
    objectFrame.RotateWorld(m3dDegToRad(-5.0f), 1.0f, 0.0f, 0.0f);
    
    if(key == GLUT_KEY_DOWN)
        objectFrame.RotateWorld(m3dDegToRad(5.0f), 1.0f, 0.0f, 0.0f);
    
    if(key == GLUT_KEY_LEFT)
        objectFrame.RotateWorld(m3dDegToRad(-5.0f), 0.0f, 1.0f, 0.0f);
    
    if(key == GLUT_KEY_RIGHT)
        objectFrame.RotateWorld(m3dDegToRad(5.0f), 0.0f, 1.0f, 0.0f);
    
    glutPostRedisplay();
}




//点击空格，切换渲染图形
void KeyPressFunc(unsigned char key, int x, int y)
{
    if(key == 32)
    {
        nStep++;
        
        if(nStep > 4)
            nStep = 0;
    }
    
    switch(nStep)
    {
        case 0:
            glutSetWindowTitle("Sphere");
            break;
        case 1:
            glutSetWindowTitle("Torus");
            break;
        case 2:
            glutSetWindowTitle("Cylinder");
            break;
        case 3:
            glutSetWindowTitle("Cone");
            break;
        case 4:
            glutSetWindowTitle("Disk");
            break;
    }
    
    glutPostRedisplay();
}


void ChangeSize(int w, int h)
{
    //放置除以零
    if ( h == 0){
        h = 1;
    }
    //1.视口
    glViewport(0, 0, w, h);
    
    //2.透视投影
    viewFrustum.SetPerspective(35.0f, float(w) / float(h), 1.0f, 500.0f);
    
    
}


int main(int argc, char* argv[])
{
    gltSetWorkingDirectory(argv[0]);
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_STENCIL);
    glutInitWindowSize(800, 600);
    glutCreateWindow("Sphere");
    glutReshapeFunc(ChangeSize);
    glutKeyboardFunc(KeyPressFunc);
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
