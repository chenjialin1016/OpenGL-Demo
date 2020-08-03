precision highp float;
varying lowp vec4 varyColor;

varying lowp vec2 varyTextCoord;

uniform sampler2D colorMap;

void main(){
    
    vec4 temp = texture2D(colorMap, varyTextCoord);
    vec4 mask = varyColor;
    
    gl_FragColor = mix(mask, temp, 0.3);
}
