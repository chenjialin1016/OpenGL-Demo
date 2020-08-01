attribute vec4 position;
attribute vec4 positionColor;

uniform mat4 projrctionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec4 varyColor;

void main(){
    varyColor = positionColor;
    
    vec4 vPos;
    vPos = projrctionMatrix * modelViewMatrix * position;
    gl_Position = vPos;
}
