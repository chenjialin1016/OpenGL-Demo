#include "GLShaderManager.h"
#include "GLTools.h"


#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif

//简单的批次容器，是GLTools的一个简单的容器类。
GLBatch squareBatch;
GLBatch greenBatch;
GLBatch redBatch;
GLBatch blueBatch;
GLBatch blackBatch;

//定义一个，着色管理器
GLShaderManager shaderManager;

//blockSize 顶点到原心得距离
GLfloat blockSize = 0.2f;

//正方形四个点的坐标
GLfloat vVerts[] = {
    -blockSize, -blockSize, 0.0f,
    blockSize, -blockSize, 0.0f,
    blockSize, blockSize, 0.0f,
    -blockSize, blockSize, 0.0f,
};

GLfloat xPos = 0.0f;
GLfloat yPos = 0.0f;


//窗口大小改变时接受新的宽度和高度，其中0,0代表窗口中视口的左下角坐标，w，h代表像素

/*
 1、窗口大小改变时，接收新的宽度 & 高度
 2、第一次创建窗口的时候
 */
void ChangeSize(int w,int h)

{
    /*
     x,y 参数代表窗口中视图的左下角坐标，而宽度、高度是像素为表示，通常x,y 都是为0
    */
    glViewport(0,0, w, h);
    
}

//为程序作一次性的设置

void SetupRC()

{
    //1.设置一个背景颜色
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    //2.初始化一个shaderManager
    shaderManager.InitializeStockShaders();
    
 
    squareBatch.Begin(GL_TRIANGLE_FAN, 4);
    squareBatch.CopyVertexData3f(vVerts);
    squareBatch.End();
    
    //绘制4个固定矩形
    GLfloat vBlock[] = { 0.25f, 0.25f, 0.0f,
        0.75f, 0.25f, 0.0f,
        0.75f, 0.75f, 0.0f,
        0.25f, 0.75f, 0.0f};
    
    greenBatch.Begin(GL_TRIANGLE_FAN, 4);
    greenBatch.CopyVertexData3f(vBlock);
    greenBatch.End();
    
    
    GLfloat vBlock2[] = { -0.75f, 0.25f, 0.0f,
        -0.25f, 0.25f, 0.0f,
        -0.25f, 0.75f, 0.0f,
        -0.75f, 0.75f, 0.0f};
    
    redBatch.Begin(GL_TRIANGLE_FAN, 4);
    redBatch.CopyVertexData3f(vBlock2);
    redBatch.End();
    
    
    GLfloat vBlock3[] = { -0.75f, -0.75f, 0.0f,
        -0.25f, -0.75f, 0.0f,
        -0.25f, -0.25f, 0.0f,
        -0.75f, -0.25f, 0.0f};
    
    blueBatch.Begin(GL_TRIANGLE_FAN, 4);
    blueBatch.CopyVertexData3f(vBlock3);
    blueBatch.End();
    
    
    GLfloat vBlock4[] = { 0.25f, -0.75f, 0.0f,
        0.75f, -0.75f, 0.0f,
        0.75f, -0.25f, 0.0f,
        0.25f, -0.25f, 0.0f};
    
    blackBatch.Begin(GL_TRIANGLE_FAN, 4);
    blackBatch.CopyVertexData3f(vBlock4);
    blackBatch.End();
    
}

//移动顶点 -> 修改每一个顶点相对位置
void SpecialKeys(int key, int x, int y)
{
    GLfloat stepSize = 0.025f;
    
    GLfloat blockX = vVerts[0];
    GLfloat blockY = vVerts[7];
    
    if(key == GLUT_KEY_UP)
        blockY += stepSize;
    
    if(key == GLUT_KEY_DOWN)
        blockY -= stepSize;
    
    if(key == GLUT_KEY_LEFT)
        blockX -= stepSize;
    
    if(key == GLUT_KEY_RIGHT)
        blockX += stepSize;
    
    
    if(blockX < -1.0f) blockX = -1.0f;
    if(blockX > (1.0f - blockSize * 2)) blockX = 1.0f - blockSize * 2;;
    if(blockY < -1.0f + blockSize * 2)  blockY = -1.0f + blockSize * 2;
    if(blockY > 1.0f) blockY = 1.0f;
    
    
    vVerts[0] = blockX;
    vVerts[1] = blockY - blockSize*2;
    
    vVerts[3] = blockX + blockSize*2;
    vVerts[4] = blockY - blockSize*2;
    
    vVerts[6] = blockX + blockSize*2;
    vVerts[7] = blockY;
    
    vVerts[9] = blockX;
    vVerts[10] = blockY;
    
    squareBatch.CopyVertexData3f(vVerts);
    
    glutPostRedisplay();
}


//开始渲染
void RenderScene(void)

{
    //1.清除一个或者一组特定的缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    //1.设置颜色RGBA
    GLfloat vRed[] = {1.0f, 0.0f, 0.0f, 0.5f};
    GLfloat vGreen[] = {0.0f, 1.0f, 0.0f, 1.0f};
    GLfloat vBlue[] = {0.0f, 0.0f, 1.0f, 1.0f};
    GLfloat vBlack[] = {0.0f, 0.0f, 0.0f, 1.0f};
    
    //当需要在一个屏幕上画不同图形时，可以通过使用不同的三角形批次类来实现
    //如果想改动不同状态，就使用不同的管线，去更新,所以4个图形，用了4个固定管线
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY, vGreen);
    greenBatch.Draw();
    
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY, vRed);
    redBatch.Draw();
    
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY, vBlue);
    blueBatch.Draw();
    
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY, vBlack);
    blackBatch.Draw();
    
    
    //组合核心代码
    //1.开启混合
    glEnable(GL_BLEND);
    //2.开启组合函数 计算混合颜色因子---每次渲染，会把屏幕上所有的像素点更新一遍
    //混合方程式：Cf = （Cs * S）+（Cd * D）
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //3.使用着色器管理器
    //*使用 单位着色器
    //参数1：简单的使用默认笛卡尔坐标系（-1，1），所有片段都应用一种颜色。GLT_SHADER_IDENTITY
    //参数2：着色器颜色
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY, vRed);
    //4.容器类开始绘制
    squareBatch.Draw();
    //5.关闭混合功能
    glDisable(GL_BLEND);
    
    //同步绘制命令
    glutSwapBuffers();
}



int main(int argc,char* argv[])

{
    
    gltSetWorkingDirectory(argv[0]);
    glutInit(&argc, argv);

    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_STENCIL);
    
    //GLUT窗口大小，标题窗口
    glutInitWindowSize(800,600);
    glutCreateWindow("Triangle");
    

    //注册重塑函数
    glutReshapeFunc(ChangeSize);
    //注册显示函数
    glutDisplayFunc(RenderScene);
    //注册特殊函数
    glutSpecialFunc(SpecialKeys);
    
    GLenum err = glewInit();
    if(GLEW_OK != err) {
        
        fprintf(stderr,"glew error:%s\n",glewGetErrorString(err));
        
        return 1;
        
    }
    
    //设置我们的渲染环境
    SetupRC();
    
    glutMainLoop();
    
    return 0;
    
}

