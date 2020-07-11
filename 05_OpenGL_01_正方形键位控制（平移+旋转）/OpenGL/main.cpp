#include "GLShaderManager.h"
/*
`#include<GLShaderManager.h>` 移入了GLTool 着色器管理器（shader Mananger）类。没有着色器，我们就不能在OpenGL（核心框架）进行着色。着色器管理器不仅允许我们创建并管理着色器，还提供一组“存储着色器”，他们能够进行一些初步䄦基本的渲染操作。
*/

#include "GLTools.h"
/*
 `#include<GLTools.h>`  GLTool.h头文件包含了大部分GLTool中类似C语言的独立函数
*/

#include <glut/glut.h>
/*
 在Mac 系统下，`#include<glut/glut.h>`
 在Windows 和 Linux上，我们使用freeglut的静态库版本并且需要添加一个宏
*/

//简单的批次容器，是GLTools的一个简单的容器类。
GLBatch triangleBatch;

//定义一个，着色管理器
GLShaderManager shaderManager;

//blockSize 顶点到原心得距离
GLfloat blockSize = 0.1f;

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
    glClearColor(0.30f, 0.40f, 0.5f, 1.0f);
    
    //2.初始化一个shaderManager
    shaderManager.InitializeStockShaders();
    
    //将 GL_TRIANGLES 修改为 GL_TRIANGLE_FAN ,4个顶点
    triangleBatch.Begin(GL_TRIANGLE_FAN, 4);
    
    //将顶点拷贝进去
    triangleBatch.CopyVertexData3f(vVerts);
    //完成
    triangleBatch.End();
    
}

//移动顶点 -> 修改每一个顶点相对位置
//使用矩阵方式（一起搞定），不需要修改每个顶点，只需要记录移动步长，碰撞检测
void SpecialKeys(int key, int x, int y){
    
   
    
    GLfloat stepSize = 0.025f;
    
    if (key == GLUT_KEY_UP) {
        
        yPos += stepSize;
    }
    
    if (key == GLUT_KEY_DOWN) {
        yPos -= stepSize;
    }
    
    if (key == GLUT_KEY_LEFT) {
        xPos -= stepSize;
    }
    
    if (key == GLUT_KEY_RIGHT) {
        xPos += stepSize;
    }
    
    //碰撞检测 xPos是平移距离，即移动量
    if (xPos < (-1.0f + blockSize)) {
        
        xPos = -1.0f + blockSize;
    }
    
    if (xPos > (1.0f - blockSize)) {
        xPos = 1.0f - blockSize;
    }
    
    if (yPos < (-1.0f + blockSize)) {
        yPos = -1.0f + blockSize;
    }
    
    if (yPos > (1.0f - blockSize)) {
        yPos = 1.0f - blockSize;
    }
    
    glutPostRedisplay();
    
}

//开始渲染
void RenderScene(void)

{
    //1.清除一个或者一组特定的缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    //1.设置颜色RGBA
    GLfloat vRed[] = {1.0f, 0.5f, 0.0f, 1.0f};
    
    
    //定义矩阵
    M3DMatrix44f mFinalTransform, mTransformMatrix, mRotationMatrix;
    
    //平移矩阵
    m3dTranslationMatrix44(mTransformMatrix, xPos, yPos, 0.0f);
    
    //每次旋转5度
    static float yRot = 0.0f;
    yRot += 5.0f;
    m3dRotationMatrix44(mRotationMatrix, m3dDegToRad(yRot), 0.0f, 0.0f, 1.0f);
    
    
    //综合--矩阵叉乘
    m3dMatrixMultiply44(mFinalTransform, mTransformMatrix, mRotationMatrix);
    
    //mvp -- 矩阵叉乘
    
    //让每一个顶点都应用平移--固定管线
    //当单元着色器不够用时，使用平面着色器
    //参数1：存储着色器类型
    //参数2：使用什么矩阵变换
    //参数3：颜色
    shaderManager.UseStockShader(GLT_SHADER_FLAT, mFinalTransform, vRed);
    
    //提交着色器
    triangleBatch.Draw();
    glutSwapBuffers();
}



int main(int argc,char* argv[])

{
    
    //设置当前工作目录，针对MAC OS X
    
    gltSetWorkingDirectory(argv[0]);
    
    //初始化GLUT库，这个函数只是传说命令参数并且初始化glut库
    glutInit(&argc, argv);
    
    /*初始化双缓冲窗口，其中标志GLUT_DOUBLE、GLUT_RGBA、GLUT_DEPTH、GLUT_STENCIL分别指
     
     双缓冲窗口、RGBA颜色模式、深度测试、模板缓冲区
     
     --GLUT_DOUBLE`：双缓存窗口，是指绘图命令实际上是离屏缓存区执行的，然后迅速转换成窗口视图，这种方式，经常用来生成动画效果；
     --GLUT_DEPTH`：标志将一个深度缓存区分配为显示的一部分，因此我们能够执行深度测试；
     --GLUT_STENCIL`：确保我们也会有一个可用的模板缓存区。
     深度、模板测试后面会细致讲到
     */
    
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_STENCIL);
    
    //GLUT窗口大小，标题窗口
    glutInitWindowSize(800,600);
    glutCreateWindow("Triangle");
    
    /*
     GLUT 内部运行一个本地消息循环，拦截适当的消息。然后调用我们不同时间注册的回调函数。我们一共注册2个回调函数：
     1）为窗口改变大小而设置的一个回调函数
     2）包含OpenGL 渲染的回调函数
     */
    //注册重塑函数
    glutReshapeFunc(ChangeSize);
    //注册显示函数
    glutDisplayFunc(RenderScene);
    
    //注册特殊函数
    glutSpecialFunc(SpecialKeys);
    
    /*
     初始化一个GLEW库，确保OpenGL API对程序完全可用
     在试图做任何渲染之前，要检查确定驱动程序的初始化过程中没有任何问题
     */
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

