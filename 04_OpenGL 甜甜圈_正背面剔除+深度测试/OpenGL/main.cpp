//演示了OpenGL背面剔除，深度测试，和多边形模式
#include "GLTools.h"
#include "GLMatrixStack.h"
#include "GLFrame.h"
#include "GLFrustum.h"
#include "GLGeometryTransform.h"

#include <math.h>
#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

////设置角色帧，作为相机
GLFrame             viewFrame;
//使用GLFrustum类来设置透视投影
GLFrustum           viewFrustum;
GLTriangleBatch     torusBatch;
GLMatrixStack       modelViewMatix;
GLMatrixStack       projectionMatrix;
GLGeometryTransform transformPipeline;
GLShaderManager     shaderManager;

//标记：背面剔除、深度测试
int iCull = 0;
int iDepth = 0;

//渲染场景
void RenderScene()
{
    //1.清除窗口和深度缓冲区
    //可以给学员演示一下不清空颜色/深度缓冲区时.渲染会造成什么问题. 残留数据
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    //开启/关闭正背面剔除功能
    if (iCull) {
        glEnable(GL_CULL_FACE);
        //以下两行是默认的，可以不写
        glFrontFace(GL_CCW);
        glCullFace(GL_BACK);
    }else
    {
        glDisable(GL_CULL_FACE);
    }
    
    if(iDepth){
        glEnable(GL_DEPTH_TEST);
    }else{
        glDisable(GL_DEPTH_TEST);
        glPolygonOffset(<#GLfloat factor#>, <#GLfloat units#>)
    }
    
    //2.把摄像机矩阵压入模型矩阵中
    modelViewMatix.PushMatrix(viewFrame);
    
    //3.设置绘图颜色
    GLfloat vRed[] = { 1.0f, 1.0f, 0.0f, 1.0f };
    
    //4.
    //使用平面着色器
    //参数1：平面着色器
    //参数2：模型视图投影矩阵
    //参数3：颜色
   // shaderManager.UseStockShader(GLT_SHADER_FLAT, transformPipeline.GetModelViewProjectionMatrix(), vRed);
    
    //使用默认光源着色器
    //通过光源、阴影效果跟提现立体效果
    //参数1：GLT_SHADER_DEFAULT_LIGHT 默认光源着色器
    //参数2：模型视图矩阵
    //参数3：投影矩阵
    //参数4：基本颜色值
    shaderManager.UseStockShader(GLT_SHADER_DEFAULT_LIGHT, transformPipeline.GetModelViewMatrix(), transformPipeline.GetProjectionMatrix(), vRed);
    
    //5.绘制
    torusBatch.Draw();

    //6.出栈 绘制完成恢复
    modelViewMatix.PopMatrix();
    
    //7.交换缓存区
    glutSwapBuffers();
}

void SetupRC()
{
    //1.设置背景颜色
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f );
    
    //2.初始化着色器管理器
    shaderManager.InitializeStockShaders();
    
    //3.将相机向后移动7个单元：肉眼到物体之间的距离
    viewFrame.MoveForward(7.0);
    
    //4.创建一个甜甜圈
    //参数1：GLTriangleBatch 容器帮助类
    //参数2：外边缘半径
    //参数3：内边缘半径
    //参数4、5：主半径和从半径的细分单元数量
    gltMakeTorus(torusBatch, 1.0f, 0.3f, 52, 26);
    
    //5.点的大小(方便点填充时,肉眼观察)
    glPointSize(4.0f);
}

//键位设置，通过不同的键位对其进行设置
//控制Camera的移动，从而改变视口
void SpecialKeys(int key, int x, int y)
{
    //1.判断方向
    if(key == GLUT_KEY_UP)
        //2.根据方向调整观察者位置
        viewFrame.RotateWorld(m3dDegToRad(-5.0), 1.0f, 0.0f, 0.0f);
    
    if(key == GLUT_KEY_DOWN)
        viewFrame.RotateWorld(m3dDegToRad(5.0), 1.0f, 0.0f, 0.0f);
    
    if(key == GLUT_KEY_LEFT)
        viewFrame.RotateWorld(m3dDegToRad(-5.0), 0.0f, 1.0f, 0.0f);
    
    if(key == GLUT_KEY_RIGHT)
        viewFrame.RotateWorld(m3dDegToRad(5.0), 0.0f, 1.0f, 0.0f);
    
    //3.重新刷新
    glutPostRedisplay();
}

//窗口改变
void ChangeSize(int w, int h)
{
    //1.防止h变为0
    if(h == 0)
        h = 1;
    
    //2.设置视口窗口尺寸
    glViewport(0, 0, w, h);
    
    //3.setPerspective函数的参数是一个从顶点方向看去的视场角度（用角度值表示）
    // 设置透视模式，初始化其透视矩阵
    viewFrustum.SetPerspective(35.0f, float(w)/float(h), 1.0f, 100.0f);
    
    //4.把透视矩阵加载到透视矩阵对阵中
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
    //5.初始化渲染管线
    transformPipeline.SetMatrixStacks(modelViewMatix, projectionMatrix);
}


void ProcessMenu(int value)
{
    switch (value) {
        case 1:
            iDepth = !iDepth;
            break;
        case 2:
            iCull = !iCull;
        case 3:
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            break;
        case 4:
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
            break;
        case 5:
            glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);
            break;
            
        default:
            break;
    }
    
    glutPostRedisplay();
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
    
    //添加右击菜单栏
    glutCreateMenu(ProcessMenu);
    glutAddMenuEntry("深度测试",1);
    glutAddMenuEntry("正背面剔除",2);
    glutAddMenuEntry("颜色填充", 3);
    glutAddMenuEntry("线填充", 4);
    glutAddMenuEntry("点填充", 5);
    glutAttachMenu(GLUT_RIGHT_BUTTON);
    
    GLenum err = glewInit();
    if (GLEW_OK != err) {
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    SetupRC();
    
    glutMainLoop();
    return 0;
}
