precision highp float;
varying lowp vec4 varyColor;

varying lowp vec2 varyTextCoord;

uniform sampler2D colorMap;

void main(){
    
    vec4 weakMask = texture2D(colorMap, varyTextCoord);
    vec4 mask = varyColor;
//    float alpha = 0.3;

//    vec4 tempColor = mask * (1.0 - alpha) + weakMask * alpha;
//    gl_FragColor = tempColor;
    
//    mix(x,y,a) return x(1-a) +y*a
    gl_FragColor = mix(mask, weakMask, 0.3);
}
