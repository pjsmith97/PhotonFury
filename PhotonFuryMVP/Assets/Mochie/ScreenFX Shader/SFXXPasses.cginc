#ifndef SFXX_PASSES_INCLUDED
#define SFXX_PASSES_INCLUDED

#if TRIPLANAR_PASS
v2f vert (appdata v){
    v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pulseSpeed = GetPulse();
    o.cameraPos = GetCameraPos();
    o.objPos = GetObjPos();
    float objDist = distance(o.cameraPos, o.objPos);

    float maxr = lerp(_TPMaxRange, _MaxRange, _TPUseGlobal);
    float minr = lerp(_TPMinRange, _MinRange, _TPUseGlobal);
    o.globalF = smoothstep(maxr, clamp(minr, 0, maxr-0.001), objDist);
	o.fogF = GetFalloff(_FogUseGlobal, o.globalF, _FogMinRange, _FogMaxRange, o.objDist);
    v.vertex.x *= 1.4;

    float4 a = mul(unity_CameraToWorld, v.vertex);
    float4 b = mul(unity_WorldToObject, a);
    o.raycast = UnityObjectToViewPos(b).xyz * float3(-1,-1,1);
    o.pos = UnityObjectToClipPos(b);
    o.uv = ComputeGrabScreenPos(o.pos);
    return o;
}

float4 frag (v2f i) : SV_Target {

    #if defined(SHADER_API_MOBILE)
		discard;
	#endif

    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	#if !FOG_ENABLED && !TRIPLANAR_ENABLED
		discard;
	#endif

    float2 uv = i.uv.xy / i.uv.w;
    i.uv.xy = uv;

	MirrorCheck();
	float4 col = 0;

	audioLinkData ald = (audioLinkData)0;
	#if AUDIOLINK_ENABLED
		InitializeAudioLink(ald, 0);
	#endif

	#if TRIPLANAR_ENABLED
        float audioLinkTriplanarOpacity = 1;
        float audioLinkTriplanarRadius = 1;
        #if AUDIOLINK_ENABLED
            audioLinkTriplanarOpacity = GetAudioLinkBand(ald, _AudioLinkTriplanarOpacity, _AudioLinkTriplanarBand, _AudioLinkTriplanarMin, _AudioLinkTriplanarMax);
            audioLinkTriplanarRadius = GetAudioLinkBand(ald, _AudioLinkTriplanarRadius, _AudioLinkTriplanarBand, _AudioLinkTriplanarMin, _AudioLinkTriplanarMax);
        #endif
		float3 tpPos = lerp(i.cameraPos, i.objPos, _TPP2O);
		float radius = GetTriplanarRadius(i, tpPos, _TPRadius, _TPFade, audioLinkTriplanarRadius);
        float4 triplanarColor = GetTriplanar(i, _TPTexture, _TPNoiseTex, _TPTexture_ST.xy, _TPNoiseTex_ST.xy, radius) * _TPColor;
		#if AUDIOLINK_ENABLED
            col = lerp(col, triplanarColor, audioLinkTriplanarOpacity);
        #else
            col = triplanarColor;
        #endif
	#endif

	#if FOG_ENABLED
		ApplyFog(i, col, ald);
	#endif
	
	col.a *= _Opacity;
	return col;
}
#endif

#if ZOOM_PASS
v2f vert (appdata v){
    v2f o = (v2f)0;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pulseSpeed = GetPulse();
    o.objPos = GetObjPos();
    o.cameraPos = GetCameraPos();
    o.objDist = distance(o.cameraPos, o.objPos);

    float maxr = lerp(_ZoomMaxRange, _MaxRange, _ZoomUseGlobal);
    float minr = lerp(_ZoomMinRange, _MinRange, _ZoomUseGlobal);
    o.globalF = smoothstep(maxr, clamp(minr, 0, maxr-0.001), o.objDist);
    o.letterbF = smoothstep(_MaxRange, clamp(_MinRange, 0, _MaxRange-0.001), o.objDist);
	o.sstF = smoothstep(_SSTMaxRange, clamp(_SSTMinRange, 0, _SSTMaxRange-0.001), o.objDist);

    v.vertex.x *= 1.4;
    float4 a = mul(unity_CameraToWorld, v.vertex);
    float4 b = mul(unity_WorldToObject, a);
    o.pos = UnityObjectToClipPos(b);
    o.uv = ComputeGrabScreenPos(o.pos);
	o.uvs = GetSSTUV(v.uv.xy);
    o.luv = o.uv.y;

    audioLinkData ald = (audioLinkData)0;
	#if AUDIOLINK_ENABLED
		InitializeAudioLink(ald, 0);
	#endif

    #if ZOOM_ENABLED
        #if AUDIOLINK_ENABLED
            _ZoomStr *= GetAudioLinkBand(ald, _AudioLinkZoomStrength, _AudioLinkZoomBand, _AudioLinkZoomMin, _AudioLinkZoomMax);
        #endif
		o.zoomPos = ComputeScreenPos(UnityObjectToClipPos(float4(0,0,0,1)));
		o.zoom = GetZoom(o.objPos, o.cameraPos, o.objDist, _ZoomMinRange, _ZoomStr);
        o.uv = lerp(o.uv, o.zoomPos, o.zoom * o.pulseSpeed);
	#endif

    #if ZOOM_RGB_ENABLED
        #if AUDIOLINK_ENABLED
            float audioLinkMultiplier = GetAudioLinkBand(ald, _AudioLinkZoomStrength, _AudioLinkZoomBand, _AudioLinkZoomMin, _AudioLinkZoomMax);
            _ZoomStrR *= audioLinkMultiplier;
            _ZoomStrG *= audioLinkMultiplier;
            _ZoomStrB *= audioLinkMultiplier;
        #endif
		o.zoomPos = ComputeScreenPos(UnityObjectToClipPos(float4(0,0,0,1)));
	    float zoomR = GetZoom(o.objPos, o.cameraPos, o.objDist, _ZoomMinRange, _ZoomStrR);
		float zoomG = GetZoom(o.objPos, o.cameraPos, o.objDist, _ZoomMinRange, _ZoomStrG);
		float zoomB = GetZoom(o.objPos, o.cameraPos, o.objDist, _ZoomMinRange, _ZoomStrB);
        o.uvR = lerp(o.uv, o.zoomPos, zoomR * o.pulseSpeed);
        o.uvG = lerp(o.uv, o.zoomPos, zoomG * o.pulseSpeed);
        o.uvB = lerp(o.uv, o.zoomPos, zoomB * o.pulseSpeed);
    #endif

    return o;
}

float4 frag (v2f i) : SV_Target {

	#if defined(SHADER_API_MOBILE)
		discard;
	#endif
    
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    float2 uv = i.uv.xy / i.uv.w;
    i.uv.xy = uv;

    MirrorCheck();
    
    audioLinkData ald = (audioLinkData)0;
	#if AUDIOLINK_ENABLED
		InitializeAudioLink(ald, 0);
	#endif

    DoLetterbox(i, ald);

	#if IMAGE_OVERLAY_DISTORTION_ENABLED
		ApplySSTAD(i);
	#endif

    if (CanLetterbox(i)) 
		return float4(0,0,0,1);

    float4 col = MOCHIE_SAMPLE_TEX2D_SCREENSPACE(_ZoomGrab, i.uv.xy);

	#if ZOOM_RGB_ENABLED
		ApplyRGBZoom(i, col.rgb);
	#endif
	
	#if IMAGE_OVERLAY_ENABLED
		ApplySST(i, col.rgb, ald);
	#endif

    return col;
}
#endif

#endif