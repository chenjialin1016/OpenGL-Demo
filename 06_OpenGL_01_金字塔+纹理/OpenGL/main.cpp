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
void MakePyramid(GLBatch& pyramidBatch){
    
    /*1、通过pyramidBatch组建三角形批次
     参数1：类型
     参数2：顶点数
     参数3：这个批次中将会应用1个纹理
     注意：如果不写这个参数，默认为0。
    */
//    MARK:--QUES:参数3 是指 纹理资源数？？？
    pyramidBatch.Begin(GL_TRIANGLES, 18, 1);
    
    /***前情导入
    
    1)设置法线
    void Normal3f(GLfloat x, GLfloat y, GLfloat z);
    Normal3f：添加一个表面法线（法线坐标 与 Vertex顶点坐标中的Y轴一致）
    表面法线是有方向的向量，代表表面或者顶点面对的方向（相反的方向）。在多数的关照模式下是必须使用。后面的课程会详细来讲法线的应用
    
    pyramidBatch.Normal3f(X,Y,Z);
    
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
    
    
    4)获取从三点找到一个法线坐标(三点确定一个面)
    void m3dFindNormal(result,point1, point2,point3);
    参数1：结果
    参数2-4：3个顶点数据
    */
    
    //塔顶
    M3DVector3f vApex = {0.0f, 1.0f, 0.0f};
    M3DVector3f vFrontLeft = {-1.0f, -1.0f, 1.0f};
    M3DVector3f vFrontRight = {1.0f, -1.0f, 1.0f};
    M3DVector3f vBackLeft = {-1.0f, -1.0f, -1.0f};
    M3DVector3f vBackRight = {1.0f, -1.0f, -1.0f};
    M3DVector3f n;
    
    //金字塔底部 = 三角形x + 三角形y
    //找到三角形x的法线, 顶点设置法线、纹理坐标，批次类添加纹理数据
    m3dFindNormal(n, vBackLeft, vBackRight, vFrontRight);
    //vBackLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    //vBackRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    //vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    //三角形Y =(vFrontLeft,vBackLeft,vFrontRight)
    //找到三角形y的法线, 顶点设置法线、纹理坐标，批次类添加纹理数据
    m3dFindNormal(n, vFrontLeft, vBackLeft, vFrontRight);
    //vBackLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    //vBackRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    //vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 1.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    //金字塔前面 （Apex，vFrontLeft，vFrontRight）
    m3dFindNormal(n, vApex, vFrontLeft, vFrontRight);
    //vBackLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    //vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    
    //金字塔左边 （vApex, vBackLeft, vFrontLeft）
    m3dFindNormal(n, vApex, vBackLeft, vFrontLeft);
    //vBackLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    //vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontLeft);
    
    
    //金字塔右边 （vApex, vFrontRight, vBackRight）
    m3dFindNormal(n, vApex, vFrontRight, vBackRight);
    //vBackLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vFrontRight);
    //vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    
    //金字塔后边 （vApex, vBackRight, vBackLeft）
    m3dFindNormal(n, vApex, vBackRight, vBackLeft);
    //vBackLeft
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.5f, 1.0f);
    pyramidBatch.Vertex3fv(vApex);
    //vBackRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 0.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackRight);
    //vFrontRight
    pyramidBatch.Normal3fv(n);
    pyramidBatch.MultiTexCoord2f(0, 1.0f, 0.0f);
    pyramidBatch.Vertex3fv(vBackLeft);
    
    pyramidBatch.End();
}

//将TGA文件加载为2D纹理
bool LoadTGATexture(const char *szFileName, GLenum minFilter, GLenum magFilter, GLenum wrapMode){
    
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
    
    //4.加载Mip,纹理生成所有的Mip层
    //参数：GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
    glGenerateMipmap(GL_TEXTURE_2D);
    
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
     LoadTGATexture("stone.tga", GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR, GL_CLAMP_TO_EDGE);
    
    
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
    
    /*5.点光源着色器
    参数1：GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF（着色器标签）
    参数2：模型视图矩阵
    参数3：投影矩阵
    参数4：视点坐标系中的光源位置
    参数5：基本漫反射颜色
    参数6：图形颜色（用纹理就不需要设置颜色。设置为0）
    */
   shaderManager.UseStockShader(GLT_SHADER_TEXTURE_POINT_LIGHT_DIFF,
    transformPipeline.GetModelViewMatrix(),
    transformPipeline.GetProjectionMatrix(),
    vLightPos, vWhite, 0);
    
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
