#include "GLTools.h"
#include "GLShaderManager.h"
#include "GLFrustum.h"
#include "GLBatch.h"
#include "GLFrame.h"
#include "GLMatrixStack.h"
#include "GLGeometryTransform.h"

#ifdef __APPLE__
#include <glut/glut.h>
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>
#endif


GLShaderManager     shaderManager;
GLMatrixStack       modelViewMatix;
GLMatrixStack       projectionMatrix;


GLFrame             objectFrame;
GLFrame             cameraFrame;

//使用GLFrustum类来设置透视投影
GLFrustum           viewFrustum;

GLGeometryTransform transformPipeline;

GLBatch             pyramidBatch;

//纹理变量，一般是无符号整数
GLuint              textureID;
M3DMatrix44f        shadowMatrix;

//绘制金字塔
void MakePyramid(GLBatch& pyramidBatch)
{
    
    /*1、通过pyramidBatch组建三角形批次
     参数1：类型
     参数2：顶点数
     参数3：这个批次中将会应用1个纹理
     注意：如果不写这个参数，默认为0。
    */
    pyramidBatch.Begin(GL_TRIANGLES, 18, 1);
    
    /***前情导入
    
    2)设置纹理坐标
    void MultiTexCoord2f(GLuint texture, GLclampf s, GLclampf t);
    参数1：texture，纹理层次，对于使用存储着色器来进行渲染，设置为0
    参数2：s：对应顶点坐标中的x坐标
    参数3：t:对应顶点坐标中的y
    (s,t,r,q对应顶点坐标的x,y,z,w)
    
    pyramidBatch.MultiTexCoord2f(0,s,t);
    
    3)void Vertex3f(GLfloat x, GLfloat y, GLfloat z);
     void Vertex3fv(M3DVector3f vVertex);
    向三角形批次类添加顶点数据(x,y,z);
     pyramidBatch.Vertex3f(-1.0f, -1.0f, -1.0f);
    */
    
    //塔顶
    M3DVector3f vApex = {0.0f, 1.0f, 0.0f};
    M3DVector3f vFrontLeft = {-1.0f, -1.0f, 1.0f};
    M3DVector3f vFrontRight = {1.0f, -1.0f, 1.0f};
    M3DVector3f vBackLeft = {-1.0f, -1.0f, -1.0f};
    M3DVector3f vBackRight = {1.0f, -1.0f, -1.0f};
    M3DVector3f n;
    
    //金字塔底部 = 三角形x + 三角形y
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    //vBackRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    //三角形Y =(vFrontLeft,vBackLeft,vFrontRight)
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    //vBackRight
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    //金字塔前面 （Apex，vFrontLeft，vFrontRight）
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    //金字塔左边 （vApex, vBackLeft, vFrontLeft）
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    
    
    //金字塔右边 （vApex, vFrontRight, vBackRight）
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    //金字塔后边 （vApex, vBackRight, vBackLeft）
    //vBackLeft
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    //vFrontRight
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    pyramidBatch.End();
}

//将TGA文件加载为2D纹理
bool LoadTGATexture(const char *szFileName, GLenum minFilter, GLenum magFilter, GLenum wrapMode)
{
    
    GLbyte *pBits;
    int nWidth, nHeight, nComponents;
    GLenum eFormat;
    
    //1、读纹理位，读取像素
    //参数1：纹理文件名称
    //参数2：文件宽度地址
    //参数3：文件高度地址
    //参数4：文件组件地址
    //参数5：文件格式地址
    //返回值：pBits,指向图像数据的指针
    pBits = gltReadTGABits(szFileName, &nWidth, &nHeight, &nComponents, &eFormat);
    if (pBits == NULL) {
        return false;
    }
    
    
    //2、设置纹理参数
    //参数1：纹理维度
    //参数2：为S/T坐标设置模式
    //参数3：wrapMode,环绕模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapMode);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapMode);
    
    //参数1：纹理维度
    //参数2：线性过滤
    //参数3：wrapMode,环绕模式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
    
    
    //3.载入纹理
    //参数1：纹理维度
    //参数2：mip贴图层次
    //参数3：纹理单元存储的颜色成分（从读取像素图是获得）
    //参数4：加载纹理宽
    //参数5：加载纹理高
    //参数6：加载纹理的深度
    //参数7：像素数据的数据类型（GL_UNSIGNED_BYTE，每个颜色分量都是一个8位无符号整数）
    //参数8：指向纹理图像数据的指针
    glTexImage2D(GL_TEXTURE_2D, 0, nComponents, nWidth, nHeight, 0, eFormat, GL_UNSIGNED_BYTE, pBits);
    
    //使用完毕释放pBits
    free(pBits);
    
    //只有minFilter 等于以下四种模式，才可以生成Mip贴图
    //GL_NEAREST_MIPMAP_NEAREST具有非常好的性能，并且闪烁现象非常弱
    //GL_LINEAR_MIPMAP_NEAREST常常用于对游戏进行加速，它使用了高质量的线性过滤器
    //GL_LINEAR_MIPMAP_LINEAR 和GL_NEAREST_MIPMAP_LINEAR 过滤器在Mip层之间执行了一些额外的插值，以消除他们之间的过滤痕迹。
    //GL_LINEAR_MIPMAP_LINEAR 三线性Mip贴图。纹理过滤的黄金准则，具有最高的精度。
//    if(minFilter == GL_LINEAR_MIPMAP_LINEAR ||
//       minFilter == GL_LINEAR_MIPMAP_NEAREST ||
//       minFilter == GL_NEAREST_MIPMAP_LINEAR ||
//       minFilter == GL_NEAREST_MIPMAP_NEAREST)
//    //4.纹理生成所有的Mip层
//    //参数：GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
//    glGenerateMipmap(GL_TEXTURE_2D);
    
    return true;
}

void SetupRC()
{
    glClearColor(0.7f, 0.7f, 0.7f, 1.0f);
    shaderManager.InitializeStockShaders();
    
    //开启深度测试
    glEnable(GL_DEPTH_TEST);
    
    //分配纹理对象 参数1:纹理对象个数，参数2:纹理对象指针
    glGenTextures(1, &textureID);
    //绑定纹理状态 参数1：纹理状态2D 参数2：纹理对象
    glBindTexture(GL_TEXTURE_2D, textureID);
    //将TGA文件加载为2D纹理
    //参数1：纹理文件名称
    //参数2&参数3：需要缩小&放大的过滤器
    //参数4：纹理坐标环绕模式
//     LoadTGATexture("stone.tga", GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR, GL_CLAMP_TO_EDGE);
//    GL_LINEAR_MIPMAP_NEAREST：在最邻近mip层，并执行最邻近过滤--
//    GL_LINEAR 线性过滤
    LoadTGATexture("stone.tga", GL_LINEAR, GL_LINEAR, GL_CLAMP_TO_EDGE);
    
    
    //创建金字塔
    MakePyramid(pyramidBatch);
    
    //相机移动
    cameraFrame.MoveForward(-10);
    
}

//清理，类似于ios中dealloc，例如删除纹理对象
void ShutdownRC(void){
    glDeleteTextures(1, &textureID);
}

void RenderScene()
{
    //设置颜色值和光源位置
    static GLfloat vLightPos[] = {1.0f, 1.0f, 0.0f};
    static GLfloat vWhite[] = {1.0f, 1.0f, 1.0f, 1.0f};
    
    //清理缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    //当前模型压栈
    modelViewMatix.PushMatrix();
    
    //添加照相机矩阵
    M3DMatrix44f mCamera;
    cameraFrame.GetCameraMatrix(mCamera);
    modelViewMatix.MultMatrix(mCamera);
    
    //创建mObjectFrame矩阵
    M3DMatrix44f mObjectFrame;
    objectFrame.GetMatrix(mObjectFrame);
    modelViewMatix.MultMatrix(mObjectFrame);
    
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    //5.纹理替换矩阵着色器
    /*
    参数1：GLT_SHADER_TEXTURE_REPLACE（着色器标签）
    参数2：模型视图投影矩阵
    参数3：纹理层
    */
   shaderManager.UseStockShader(GLT_SHADER_TEXTURE_REPLACE,
    transformPipeline.GetModelViewProjectionMatrix(),0);
    
    //绘制金字塔
    pyramidBatch.Draw();
    
    //模型视图出栈
    modelViewMatix.PopMatrix();
    
    //交换缓冲区
    glutSwapBuffers();
    
}


void SpecialKeys(int key, int x, int y)
{
    if(key == GLUT_KEY_UP)
        objectFrame.RotateWorld(m3dDegToRad(-5.0f), 1.0f, 0.0f, 0.0f);
    
    if(key == GLUT_KEY_DOWN)
        objectFrame.RotateWorld(m3dDegToRad(5.0f), 1.0f, 0.0f, 0.0f);
    
    if(key == GLUT_KEY_LEFT)
        objectFrame.RotateWorld(m3dDegToRad(-5.0f), 0.0f, 1.0f, 0.0f);
    
    if(key == GLUT_KEY_RIGHT)
        objectFrame.RotateWorld(m3dDegToRad(5.0f), 0.0f, 1.0f, 0.0f);
    
    glutPostRedisplay();
}

void ChangeSize(int w, int h)
{
    //1、设置视口
    glViewport(0, 0, w, h);
    
    //2、设置投影方式，得到投影矩阵，并将其加载到投影矩阵堆栈
    viewFrustum.SetPerspective(35.0, float(w)/float(h), 1.0f, 500.0f);
    projectionMatrix.LoadMatrix(viewFrustum.GetProjectionMatrix());
    
    //设置变换管道以便使用两个矩阵堆栈
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
    
    ShutdownRC();
    
    return 0;
}
