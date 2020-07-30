precision highp float;
varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;

void main(){
//    gl_FragColor = texture2D(colorMap, varyTextCoord);
    gl_FragColor = texture2D(colorMap, vec2(varyTextCoord.x, 1.0-varyTextCoord.y));
}
