// UNIFORMS
uniform highp mat4      u_mvpMatrix;
uniform sampler2D       u_samplers2D[1];
uniform highp vec3      u_gravity;
uniform highp float     u_elapsedSeconds;

// Varyings
varying lowp float      v_particleOpacity;


void main()
{
   
    //http://blog.csdn.net/hgl868/article/details/7876246
    //通过texture2D函数我们可以得到一个纹素（texel），这是一个纹理图片中的像素。函数参数分别为simpler2D以及纹理坐标：
    // gl_PointCoord是片元着色器的内建只读变量，它的值是当前片元所在点图元的二维坐标。点的范围是0.0到1.0
    lowp vec4 textureColor = texture2D(u_samplers2D[0], gl_PointCoord);
    
    
    //粒子透明度 与 v_particleOpacity 值相关
    textureColor.a = textureColor.a * v_particleOpacity;
    
    //设置片元颜色值
    gl_FragColor = textureColor;
}
