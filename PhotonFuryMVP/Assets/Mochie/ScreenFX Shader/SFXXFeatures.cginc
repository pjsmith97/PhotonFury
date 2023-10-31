 	#ifndef SFXX_FEATURES_INCLUDED
#define SFXX_FEATURES_INCLUDED

float GetPulse(){
    float p = 1;
    if (_Pulse == 1){
        switch (_WaveForm){
            case 1: p = smoothstep(-1, 1, sin(_Time.y * _PulseSpeed)); break;
            case 2:	p = frac(_Time.y * (_PulseSpeed*0.5)); break;
            case 3: p = 1-frac(_Time.y * (_PulseSpeed*0.5)); break;
            case 4: p = round(frac(_Time.y * (_PulseSpeed*0.25))); break;
            case 5: p = abs((_Time.y * (_PulseSpeed*0.25)%2)-1); break;
            default: break;
        }  
    }
    return p;
}

void ApplyNormalMap(v2f i, inout float3 col, float miscAudioLinkStrength){
	if (_NMFToggle == 1){
		float2 uv = i.uv.xy;
		float2 l = uv + (float2(1,0)*_MSFXGrab_TexelSize);
		float2 r = uv + (float2(-1,0)*_MSFXGrab_TexelSize);
		float2 u = uv + (float2(0,1)*_MSFXGrab_TexelSize);
		float2 d = uv + (float2(0,-1)*_MSFXGrab_TexelSize);
		float M = Desaturate(col).r;
		float L = GrayscaleSample(l);
		float R = GrayscaleSample(r);	
		float U = GrayscaleSample(u);
		float D = GrayscaleSample(d);
		float X = ((R-M)+(M-L))*.5;
		float Y = ((D-M)+(M-U))*.5;
		float3 nmCol = 0.5 + (normalize(float3(X, Y, 1-_NormalMapFilter))) * 0.5;
		nmCol.rg = 1-nmCol.rg;
		float interpolator = i.globalF*_NMFOpacity*i.pulseSpeed;
		#if AUDIOLINK_ENABLED
			interpolator *= miscAudioLinkStrength;
		#endif
		col = lerp(col, nmCol, interpolator);
	}
}

void ApplyDepthBuffer(v2f i, inout float3 col, float miscAudioLinkStrength){
	if (_DepthBufferToggle == 1){
		float2 uv = i.uv.xy;
		float3 depth = SampleDepthTex(uv) + GetNoise(uv, 0.001);
		depth *= _DBColor;
		float interpolator = _DBOpacity*i.globalF*i.pulseSpeed;
		#if AUDIOLINK_ENABLED
			interpolator *= miscAudioLinkStrength;
		#endif
		col = lerp(col, depth, interpolator);
	}
}

// ---------------------------
// Fog
// ---------------------------
float GetFogFalloff(float globalFalloff, float minRange, float objDist){
    float falloff = smoothstep(_FogMaxRange, minRange, objDist);
    falloff = min(globalFalloff, falloff);
    return falloff;
}

void ApplyFog(v2f i, inout float4 col, audioLinkData ald){
	#if AUDIOLINK_ENABLED
		_FogRadius *= GetAudioLinkBand(ald, _AudioLinkFogRadius, _AudioLinkFogBand, _AudioLinkFogMin, _AudioLinkFogMax);
	#endif
	if (_FogSafeZone == 1){
		_FogSafeMaxRange = max(_FogRadius, _FogSafeMaxRange)+0.001;
		float enterSafety = smoothstep(_FogSafeMaxRange, _FogRadius, i.objDist);
		_FogRadius = lerp(_FogRadius, _FogSafeRadius, enterSafety);
		_FogP2O = lerp(_FogP2O, 1, enterSafety);
		_FogColor.a *= lerp(1, _FogSafeOpacity, enterSafety);
	}
	float noiseStr = (_FogColor.r+_FogColor.g+_FogColor.b)/3;
	noiseStr = lerp(0.0033,0.01,noiseStr);
	_FogColor.rgb += GetNoise(i.uv.xy, noiseStr);
	float3 fogSpace = lerp(i.cameraPos, i.objPos, _FogP2O);
	float radius = 1-GetRadius(i, fogSpace, _FogRadius, _FogFade);
	_FogColor.a *= i.fogF;
	_FogColor.a *= i.pulseSpeed;
	float3 fogCol = _FogColor.rgb;
	float fogAlpha = _FogColor.a;
	#if AUDIOLINK_ENABLED
		float audioLinkOpacity = GetAudioLinkBand(ald, _AudioLinkFogOpacity, _AudioLinkFogBand, _AudioLinkFogMin, _AudioLinkFogMax);
		fogCol = lerp(col.rgb, _FogColor.rgb, audioLinkOpacity);
		fogAlpha = lerp(col.rgb, _FogColor.a, audioLinkOpacity);
	#endif
	col.rgb = lerp(col.rgb, fogCol, radius);
	col.a = lerp(col.a, fogAlpha, radius);
}

// ---------------------------
// Screenspace Texture Overlay
// ---------------------------
float2 ScaleUV(float2 uv0){
    uv0.x += _SSTLR;
    uv0.y -= _SSTUD;
    uv0.xy = (uv0.xy - 0.5) * _SSTScale + 0.5;
    uv0.x = (uv0.x - 0.5) * (_SSTWidth*-1.4) + 0.5;
    uv0.y = (uv0.y - 0.5) * _SSTHeight + 0.5;
    return uv0.xy;
}

float2 GetSSTUV(float2 uv0){
    float2 uv1 = ScaleUV(uv0);
	if (_SST >= 2){
		float2 size = float2(1/_SSTColumnsX, 1/_SSTRowsY);
		uint totalFrames = _SSTColumnsX * _SSTRowsY;
		uint index = 0;
		index = lerp(_Time.y*_SSTAnimationSpeed, _ScrubPos, _ManualScrub);
		uint indexX = index % _SSTColumnsX;
		uint indexY = floor((index % totalFrames) / _SSTColumnsX);
		float2 offset = float2(size.x*indexX,-size.y*indexY);
		float2 uv2 = uv1*size;
		uv2.y = uv2.y + size.y*(_SSTRowsY - 1);
		uv1 = uv2 + offset;
	}
    return uv1;
}

void ApplySSTBlend(v2f i, inout float3 col, float audioLinkMultiplier){
    float4 texCol = tex2D(_ScreenTex, i.uvs.xy) * _SSTColor;
    col = lerp(col, texCol.rgb, texCol.a*i.sstF*audioLinkMultiplier);
}

void ApplySSTAdd(v2f i, inout float3 col, float audioLinkMultiplier){
    float4 texCol = tex2D(_ScreenTex, i.uvs.xy) * _SSTColor;
    texCol.rgb = col + texCol.rgb;
    texCol *= _SSTColor;
    col = lerp(col, texCol.rgb, texCol.a*i.sstF*audioLinkMultiplier);
}

void ApplySSTMult(v2f i, inout float3 col, float audioLinkMultiplier){
    float4 texCol = tex2D(_ScreenTex, i.uvs.xy) * _SSTColor;
    texCol.rgb = col * texCol.rgb;
    texCol *= _SSTColor;
    col = lerp(col, texCol, texCol.a*i.sstF*audioLinkMultiplier);
}

void ApplySSTAD(inout v2f i){
    float2 uv0 = i.uv.xy;
	float2 uv2 = i.uvs;
	float2 animOffsetTex = UnpackNormal(tex2D(_ScreenTex, uv2)).rg;
	_SSTAnimatedDist *= i.sstF;
	float2 animOffset = animOffsetTex * _SSTAnimatedDist * _MSFXGrab_TexelSize.xy;
	uv0 += (animOffset * UNITY_Z_0_FAR_FROM_CLIPSPACE(i.uv.z));
	i.uv.xy = uv0;
}

void ApplySST(v2f i, inout float3 col, audioLinkData ald){
	float audioLinkMultiplier = 1;
	#if AUDIOLINK_ENABLED
		audioLinkMultiplier = GetAudioLinkBand(ald, _AudioLinkSSTStrength, _AudioLinkSSTBand, _AudioLinkSSTMin, _AudioLinkSSTMax);
	#endif
	switch (_SSTBlend){
		case 0: ApplySSTBlend(i, col, audioLinkMultiplier); break;
		case 1: ApplySSTAdd(i, col, audioLinkMultiplier); break;
		case 2: ApplySSTMult(i, col, audioLinkMultiplier); break;
		default: break;
	}
}

// ---------------------------
// Extras
// ---------------------------

void ApplyRounding(v2f i, inout float3 col, float miscAudioLinkStrength){
	if (_RoundingToggle == 1){
		float3 roundedCol = col*(round(col.rgb*_Rounding)/_Rounding)+lerp(0, col*0.5, linearstep(0,100,_Rounding));
		float interpolator = _RoundingOpacity*i.globalF;
		#if AUDIOLINK_ENABLED
			interpolator *= miscAudioLinkStrength;
		#endif
		col = lerp(col, roundedCol, interpolator);
	}
}

void ApplyPulse(float p){
    p = lerp(1, p, _Pulse);
	_Amplitude *= p;
	_DistortionStr *= p;
	_BlurStr *= p;
	_PixelationStr *= p;
	_RippleGridStr *= p;
	_FogColor.a *= p;
	_ShiftX *= p;
	_ShiftY *= p;
}

void ApplyUVShift(inout v2f i, audioLinkData ald){
	float2 shiftedUV = i.uv.xy;
	#if AUDIOLINK_ENABLED
		float audioLinkMultiplier = GetAudioLinkBand(ald, _AudioLinkMiscStrength, _AudioLinkMiscBand, _AudioLinkMiscMin, _AudioLinkMiscMax);
		_ShiftY *= audioLinkMultiplier;
		_ShiftX *= audioLinkMultiplier;
	#endif
    shiftedUV.x -= _ShiftX * i.globalF;
    shiftedUV.y -= _ShiftY * i.globalF;
    i.uv.xy = lerp(i.uv.xy, shiftedUV, _Shift);
}

void ApplyUVInvert(inout v2f i){
	float2 invertedUV = i.uv.xy;
    float falloff = step(i.objDist, _MaxRange);
	invertedUV.x = lerp(invertedUV.x, 1-invertedUV.x, _InvertX*falloff);
    invertedUV.y = lerp(invertedUV.y, 1-invertedUV.y, _InvertY*falloff);
	i.uv.xy = lerp(i.uv.xy, invertedUV, _Shift);
}
 
void ApplyUVManip(inout v2f i, audioLinkData ald){
	ApplyUVShift(i, ald);
	ApplyUVInvert(i);
}

// ---------------------------
// Outline
// ---------------------------
void SobelKernel(v2f i, inout float n[8], audioLinkData ald){
    _OutlineThiccS = lerp(0.24, 1.26, _OutlineThiccS);
	#if AUDIOLINK_ENABLED
		float audioLinkMultiplier = GetAudioLinkBand(ald, _AudioLinkOutlineStrength, _AudioLinkOutlineBand, _AudioLinkOutlineMin, _AudioLinkOutlineMax);
		_OutlineThiccS *= audioLinkMultiplier;
	#endif
    float2 wh = _MSFXGrab_TexelSize.xy*_OutlineThiccS;
    n[0] = SampleDepthTex((i.uv.xy + float2(-wh.x,-wh.y)));
    n[1] = SampleDepthTex((i.uv.xy + float2(0,-wh.y)));
    n[2] = SampleDepthTex((i.uv.xy + float2(wh.x,-wh.y)));
    n[3] = SampleDepthTex((i.uv.xy + float2(-wh.x,0)));
    n[4] = SampleDepthTex((i.uv.xy + float2(wh.x,0)));
    n[5] = SampleDepthTex((i.uv.xy + float2(-wh.x,wh.y)));
    n[6] = SampleDepthTex((i.uv.xy + float2(0,wh.y)));
    n[7] = SampleDepthTex((i.uv.xy + float2(wh.x,wh.y)));
}

float GetSobel(v2f i, audioLinkData ald){
    float n[8];
    SobelKernel(i, n, ald);
    float edge_h = (n[2] + n[4] + n[7]) - (n[0] + n[3] + n[5]);
    float edge_v = (n[0] + n[1] + n[2]) - (n[5] + n[6] + n[7]);
    return sqrt((edge_h * edge_h) + (edge_v * edge_v));
}

float3 GetAura(v2f i, float3 col, audioLinkData ald){
	_AuraStr *= 25;
	#if AUDIOLINK_ENABLED
		float audioLinkMultiplier = GetAudioLinkBand(ald, _AudioLinkOutlineStrength, _AudioLinkOutlineBand, _AudioLinkOutlineMin, _AudioLinkOutlineMax);
		_AuraStr *= audioLinkMultiplier;
	#endif
	_AuraFade = clamp(_AuraFade * 0.0005, 0.0001, 1);
	_AuraFade = lerp(0,5,_AuraFade);
	float2 uv = i.uv.xy;
	float baseDepth = DecodeFloatRG(SampleDepthTex(uv));
	float blurDepth = 0;
	ApplyStandardBlurDepth(i.uv, _AuraSampleCount, _AuraStr, blurDepth);
	float interpolator = linearstep(0, _AuraFade, blurDepth-baseDepth);
	col = lerp(col, _BackgroundCol.rgb, _BackgroundCol.a);
	col = lerp(col, (1-blurDepth)*_OutlineCol.rgb, interpolator);
	return col;
}

float3 SoftOutline(v2f i, float3 bg, audioLinkData ald){
    float sobel = GetSobel(i, ald);
    sobel *= sobel * 1000;
    sobel = saturate(sobel);
	if (_SobelClearInner == 1){
		sobel = saturate(sobel - DecodeFloatRG(SampleDepthTex(i.uv.xy)));
	}
    float interpolator = saturate(sobel*_OutlineThresh)*_OutlineCol.a;
    return lerp(bg, _OutlineCol.rgb, interpolator);
}

void ApplyOutline(v2f i, inout float3 col, audioLinkData ald){
	float3 bg = lerp(col, _BackgroundCol.rgb, _BackgroundCol.a);
	float falloff = i.olF * i.pulseSpeed;
	UNITY_BRANCH
	if (_OutlineType == 1)
		col = lerp(col, SoftOutline(i, bg, ald), falloff);
	else if (_OutlineType == 2)
		col = lerp(col, GetAura(i, col, ald), falloff);
}

// ---------------------------
// Letterbox
// ---------------------------
bool CanLetterbox(v2f i){
    return (_Letterbox == 1 && ((i.luv >= (0.5-_LetterboxStr)) || (i.luv <= (_LetterboxStr))));
}

void DoLetterbox(v2f i, audioLinkData ald){
	#if AUDIOLINK_ENABLED
		_LetterboxStr *= GetAudioLinkBand(ald, _AudioLinkMiscStrength, _AudioLinkMiscBand, _AudioLinkMiscMin, _AudioLinkMiscMax);
	#endif
    if (_UseZoomFalloff == 1)
        _LetterboxStr *= i.zoom*(2+_LetterboxStr);
    else
        _LetterboxStr *= i.letterbF;
}

// ---------------------------
// Zoom
// ---------------------------
float2 GetZoom(float3 objPos, float3 cameraPos, float objDist, float zoomMinRange, float zoomStr){
    float2 zoom = 0;
    if (_ZoomUseGlobal){
        _ZoomMaxRange = _MaxRange;
        _ZoomMinRange = _MinRange;
    }
	float3 a, b, c;
	zoomStr = 1.0/lerp(1.0, 1.5, zoomStr);
	b = mul(unity_CameraToWorld, float4(0,0,1,1)).xyz-_WorldSpaceCameraPos;
	#if UNITY_SINGLE_PASS_STEREO || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		a = normalize(unity_StereoWorldSpaceCameraPos[1] - unity_StereoWorldSpaceCameraPos[0]);
		b = normalize(b-dot(a,b)*a);
		c = normalize(objPos-cameraPos);
	#else
		b = normalize(b);
		c = normalize(objPos-_WorldSpaceCameraPos);
	#endif
	float zoomAmt = dot(b, c);
	float zoomed = 0;
	if (zoomAmt > zoomStr)
		zoomed = (zoomAmt - zoomStr) / zoomStr;
	float3 camDist = abs(objDist);
	float falloff = saturate((camDist - _ZoomMaxRange) / (zoomMinRange - _ZoomMaxRange));
	zoom.x = smoothlerp(0, zoomed, falloff);
	zoom.y = zoomed*falloff*2.0;
    return zoom;
}

void ApplyRGBZoom(v2f i, inout float3 col){
	i.uvR.xy /= i.uvR.w;
	i.uvG.xy /= i.uvG.w;
	i.uvB.xy /= i.uvB.w;
	col.r = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_ZoomGrab, i.uvR.xy).r;
	col.g = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_ZoomGrab, i.uvG.xy).g;
	col.b = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_ZoomGrab, i.uvB.xy).b;
}

// ---------------------------
// Sobel Filter
// ---------------------------
void SobelKernel(inout float3 n[9], float2 coord){
	float w = _MSFXGrab_TexelSize.x;
	float h = _MSFXGrab_TexelSize.y;
	n[0] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(-w, -h));
	n[1] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(0.0, -h));
	n[2] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(w, -h));
	n[3] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(-w, 0.0));
	n[4] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord);
	n[5] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(w, 0.0));
	n[6] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(-w, h));
	n[7] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(0.0, h));
	n[8] = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_MSFXGrab, coord + float2(w, h));
}

void ApplySobelFilter(v2f i, inout float3 col, float audioLinkStrength){
	float3 n[9];
	float2 coords = i.uv.xy;
	SobelKernel(n, coords);
	float3 sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
	float3 sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
	float3 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));
	float3 backgroundCol = lerp(col, _SobelFilterBackgroundColor, _SobelFilterBackgroundColor.a);
	float3 sobelCol = lerp(backgroundCol, _SobelFilterColor, Average(sobel));
	_SobelFilterOpacity *= audioLinkStrength;
	col = lerp(col, sobelCol, _SobelFilterOpacity * i.globalF * i.pulseSpeed);
}
#endif