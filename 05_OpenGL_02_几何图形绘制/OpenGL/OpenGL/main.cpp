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
    
    //2.开启深度测试
    glEnable(GL_DEPTH_TEST);

    //--------------方式一：观察者动，物体不动---------
    //3、让观察者移动15单位(即离观察者更近一些 为 -，远离为 +)，物体移动，值越大，离观察者越远：观察者动，物体不动
//    cameraFrame.MoveForward(-15.0f);
    
    //--------------方式二：观察者不动，物体动---------
    //改为---将物体向屏幕外移动15.0：观察着不动，物体动
    objectFrame.MoveForward(15.0f);
    

    //4.利用三角形批次类构造图形对象
    // 球
    /*
      gltMakeSphere(GLTriangleBatch& sphereBatch, GLfloat fRadius, GLint iSlices, GLint iStacks);
     参数1：sphereBatch，三角形批次类对象
     参数2：fRadius，球体半径
     参数3：iSlices，从球体底部堆叠到顶部的三角形带的数量；其实球体是一圈一圈三角形带组成
     参数4：iStacks，围绕球体一圈排列的三角形对数
     
     建议：一个对称性较好的球体的片段数量是堆叠数量的2倍，就是iStacks = 2 * iSlices;
     绘制球体都是围绕Z轴，这样+z就是球体的顶点，-z就是球体的底部。
     */
    gltMakeSphere(sphereBatch, 3.0, 10, 30);
    
    // 环面
    /*
     gltMakeTorus(GLTriangleBatch& torusBatch, GLfloat majorRadius, GLfloat minorRadius, GLint numMajor, GLint numMinor);
     参数1：torusBatch，三角形批次类对象
     参数2：majorRadius,甜甜圈中心到外边缘的半径
     参数3：minorRadius,甜甜圈中心到内边缘的半径
     参数4：numMajor,沿着主半径的三角形数量
     参数5：numMinor,沿着内部较小半径的三角形数量
     */
    gltMakeTorus(torusBatch, 3.0f, 0.75f, 15, 15);
    
    // 圆柱
    /*
     void gltMakeCylinder(GLTriangleBatch& cylinderBatch, GLfloat baseRadius, GLfloat topRadius, GLfloat fLength, GLint numSlices, GLint numStacks);
     参数1：cylinderBatch，三角形批次类对象
     参数2：baseRadius,底部半径
     参数3：topRadius,头部半径
     参数4：fLength,圆形长度
     参数5：numSlices,围绕Z轴的三角形对的数量
     参数6：numStacks,圆柱底部堆叠到顶部圆环的三角形数量
     */
    gltMakeCylinder(cylinderBatch, 2.0f, 2.0f, 3.0f, 15, 2);
    
    //锥
    /*
     void gltMakeCylinder(GLTriangleBatch& cylinderBatch, GLfloat baseRadius, GLfloat topRadius, GLfloat fLength, GLint numSlices, GLint numStacks);
     参数1：cylinderBatch，三角形批次类对象
     参数2：baseRadius,底部半径
     参数3：topRadius,头部半径
     参数4：fLength,圆形长度
     参数5：numSlices,围绕Z轴的三角形对的数量
     参数6：numStacks,圆柱底部堆叠到顶部圆环的三角形数量
     */
    //圆柱体，从0开始向Z轴正方向延伸。
    //圆锥体，是一端的半径为0，另一端半径可指定。
    gltMakeCylinder(coneBatch, 0.0f, 2.0f, 3.0f, 13, 2);
    
    // 磁盘
    /*
    void gltMakeDisk(GLTriangleBatch& diskBatch, GLfloat innerRadius, GLfloat outerRadius, GLint nSlices, GLint nStacks);
     参数1:diskBatch，三角形批次类对象
     参数2:innerRadius,内圆半径
     参数3:outerRadius,外圆半径
     参数4:nSlices,圆盘围绕Z轴的三角形对的数量
     参数5:nStacks,圆盘外网到内围的三角形数量
     */
    gltMakeDisk(diskBatch, 1.5f, 3.0f, 13, 3);
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
    //1、清除当前的颜色和深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //--------------方式二：观察者不动，物体不动---------
    //模型视图矩阵栈堆，压栈
    modelViewMatrix.PushMatrix(objectFrame);
    
    //--------------方式一：观察者动，物体不动---------
    //压入一个单元矩阵，push和pop是成对出现的
//    modelViewMatrix.PushMatrix();
//    //观察者矩阵压栈
//    M3DMatrix44f mCameraFrame;
    //为什么不能直接将 mcameraFrame，直接放入 cameraFrame？？？？
//   ！！！！！！！！！是因为在 PushMatrix方法中获取的是GetMatrix，而我们需要的是GetCameraMatrix
//    cameraFrame.GetCameraMatrix(mCameraFrame);
//    modelViewMatrix.MultMatrix(mCameraFrame);
//
//    //物体矩阵
//    M3DMatrix44f mObjectFrame;
//    objectFrame.GetMatrix(mObjectFrame);
//    modelViewMatrix.MultMatrix(mObjectFrame);
    
    
    //判断当前绘制的是哪个图形
    switch (nStep) {
        case 0:
            DrawWireFramedBatch(&sphereBatch);
            break;
        case 1:
            DrawWireFramedBatch(&torusBatch);
            break;
        case 2:
            DrawWireFramedBatch(&cylinderBatch);
            break;
        case 3:
            DrawWireFramedBatch(&coneBatch);
            break;
        case 4:
            DrawWireFramedBatch(&diskBatch);
            break;
    }
    
    //pop
    modelViewMatrix.PopMatrix();
    
    glutSwapBuffers();
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
    //1.视口
    glViewport(0, 0, w, h);
    
    //2.透视投影
    viewFrustum.SetPerspective(35.0f, float(w) / float(h), 1.0f, 500.0f);
    //projectionMatrix 矩阵堆栈 加载透视投影矩阵
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
    //3.modelViewMatrix 矩阵堆栈 加载单元矩阵
    modelViewMatrix.LoadIdentity();
    
    //4.通过GLGeometryTransform管理矩阵堆栈
    //使用transformPipeline 管道管理模型视图矩阵堆栈 和 投影矩阵堆栈
    transformPipeline.SetMatrixStacks(modelViewMatrix, projectionMatrix);
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
