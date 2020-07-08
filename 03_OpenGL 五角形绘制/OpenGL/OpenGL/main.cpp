#include "GLShaderManager.h"

#include "GLTools.h"

#include <glut/glut.h>

GLBatch triangleBatch;

GLShaderManager shaderManager;



void draw(void)

{
    
    glClearColor(0.5f, 0.5f, 0.5f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //设置颜色
    glColor3f(0.2f, 0.6f, 0.5f);
    
    //开始渲染
    glBegin(GL_POLYGON);
    
    //圆的顶点数：数越大越趋近于圆
    const int n = 55;
    const GLfloat R = 0.5f;
    const GLfloat pi = 3.1415926f;
    
    for (int i = 0; i < n; i++) {
        glVertex2f(R*cos(2*pi/n * i), R*sin(2*pi/n * i));
    }
    
    //结束渲染
    glEnd();
    
    //强制刷新缓存区
    glFlush();
    
    
}

int main(int argc,char* argv[])

{
    
    //设置当前工作目录，针对MAC OS X
    
    gltSetWorkingDirectory(argv[0]);
    
    //初始化GLUT库，这个函数只是传说命令参数并且初始化glut库
    glutInit(&argc, argv);
    
    //GLUT窗口大小，标题窗口
    glutCreateWindow("Triangle");

    //注册显示函数
    glutDisplayFunc(draw);
 
    
    glutMainLoop();
    
    return 0;
    
}

