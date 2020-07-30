attribute vec4 position;
attribute vec2 textCoordinate;
varying lowp vec2 varyTextCoord;

void main(){
//    varyTextCoord = textCoordinate;
    varyTextCoord = vec2(textCoordinate.x, 1.0-textCoordinate.y);
    gl_Position = position;
}
