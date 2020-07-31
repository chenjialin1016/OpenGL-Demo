attribute vec4 position;
attribute vec2 textCoordinate;
uniform mat4 rotateMatrix;
uniform mat4 scaleMatrix;
varying lowp vec2 varyTextCoord;

void main(){
    varyTextCoord = textCoordinate;
    
    vec4 vPos = position;
    vPos = vPos * rotateMatrix * scaleMatrix;
    
    gl_Position = vPos;
    
    
}
