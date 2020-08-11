precision highp float;
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

const vec2 TexSize = vec2(400.0, 400.0);
const vec2 MosaicSize = vec2(16.0, 16.0);

void main(){
    
    vec2 intXY = vec2(TextureCoordsVarying.x * TexSize.x, TextureCoordsVarying.y * TexSize.y);
    vec2 XYMosaic = vec2(floor(intXY.x/MosaicSize.x)*MosaicSize.x, floor(intXY.y/MosaicSize.y)*MosaicSize.y);

    vec2 UVMosaic = vec2(XYMosaic.x/TexSize.x, XYMosaic.y/TexSize.y);

    vec4 color = texture2D(Texture, UVMosaic);

    gl_FragColor = color;
//        vec2 XYMosaic = vec2(floor(TextureCoordsVarying.x*mosaicSize.x)/mosaicSize.x, floor(TextureCoordsVarying.y*mosaicSize.y)/mosaicSize.y);
//        vec4 color = texture2D(Texture, XYMosaic);
        gl_FragColor = color;
}
