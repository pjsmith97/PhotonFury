//----------------------------
// Vertex Shader
//----------------------------
#if X_FEATURES

void ApplyOffsets(inout float3 vertex, float3 objPos){
	vertex.xyz *= _Position.z;
    vertex += float3(_Position.x, _Position.y, -0.5);
	float camDist = distance(objPos, _WorldSpaceCameraPos);
	if (camDist > _Range)
		vertex = 0.0/_NaNLmao; 
}

void VertX(inout v2g o, inout appdata v, audioLinkData al){

	float4 localPos = v.vertex;
	#if FORWARD_PASS || ADDITIVE_PASS
	if (_Screenspace == 1){
		localPos.xyz = Rotate3D(localPos.xyz, _Rotation);
		localPos.xyz = Rotate3D(localPos.xyz, _Rotation);
		v.normal = Rotate3D(v.normal, _Rotation);
		ApplyOffsets(localPos.xyz, o.objPos);

		o.worldPos = mul(UNITY_MATRIX_I_V, localPos);
		#if VERTEX_MANIP_ENABLED
			if (_VertexRounding > 0){
				#if AUDIOLINK_ENABLED
					float vertManipAL = GetAudioLinkBand(al, _AudioLinkVertManipBand, _AudioLinkRemapVertManipMin, _AudioLinkRemapVertManipMax);
					_VertexRounding *= lerp(1, vertManipAL, _AudioLinkVertManipMultiplier*_AudioLinkStrength);
				#endif
				ApplyVertRounding(o.worldPos, localPos, _VertexRoundingPrecision, _VertexRounding, o.roundingMask);
			}
		#endif
		o.pos = mul(UNITY_MATRIX_P, localPos);
		o.normal = mul((float3x3)UNITY_MATRIX_I_V, v.normal);
		o.tangent.xyz = mul((float3x3)UNITY_MATRIX_I_V, v.tangent.xyz);
		o.grabPos = ComputeGrabScreenPos(o.pos);
		o.screenPos = ComputeScreenPos(o.pos);
	}
	else {
		o.worldPos = mul(unity_ObjectToWorld, localPos);
		#if VERTEX_MANIP_ENABLED
			if (_VertexRounding > 0){
				#if AUDIOLINK_ENABLED
					float vertManipAL = GetAudioLinkBand(al, _AudioLinkVertManipBand, _AudioLinkRemapVertManipMin, _AudioLinkRemapVertManipMax);
					_VertexRounding *= lerp(1, vertManipAL, _AudioLinkVertManipMultiplier*_AudioLinkStrength);
				#endif
				ApplyVertRounding(o.worldPos, localPos, _VertexRoundingPrecision, _VertexRounding, o.roundingMask);
			}
		#endif
		o.pos = UnityObjectToClipPos(localPos);
		o.normal = UnityObjectToWorldNormal(v.normal);
		o.tangent.xyz = UnityObjectToWorldDir(v.tangent.xyz);
		o.grabPos = ComputeGrabScreenPos(o.pos);
		o.screenPos = ComputeScreenPos(o.pos);
	}
	#endif

	#if SHADOW_PASS
		if (_Screenspace == 0){
			o.worldPos = mul(unity_ObjectToWorld, localPos);
			#if VERTEX_MANIP_ENABLED
				if (_VertexRounding > 0){
					#if AUDIOLINK_ENABLED
						float vertManipAL = GetAudioLinkBand(al, _AudioLinkVertManipBand, _AudioLinkRemapVertManipMin, _AudioLinkRemapVertManipMax);
						_VertexRounding *= lerp(1, vertManipAL, _AudioLinkVertManipMultiplier*_AudioLinkStrength);
					#endif
					ApplyVertRounding(o.worldPos, localPos, _VertexRoundingPrecision, _VertexRounding, o.roundingMask);
				}
			#endif
			o.pos = UnityObjectToClipPos(localPos);
			o.grabPos = ComputeGrabScreenPos(o.pos);
			o.screenPos = ComputeScreenPos(o.pos);
		} 
		else {
			o.pos = 0.0/_NaNLmao;
		}
	#endif
	o.uv1.xy = TRANSFORM_TEX(v.uv, _DissolveTex) + (_Time.y * 0.03 * _DissolveScroll0);
}

//----------------------------
// Geometry Shader
//----------------------------
static const float3 bCoordsN[3] = {
	float3(1,0,0),
	float3(0,1,0),
	float3(0,0,1)
};

float4 GetCloneCoords(uint instanceID){
	float4 coords[9] = { 
		float4(0,0,0,0), 
		_Clone1, _Clone2, 
		_Clone3, _Clone4, 
		_Clone5, _Clone6, 
		_Clone7, _Clone8
	};
	return coords[instanceID];
}

void GetBarycentricCoords(inout float3 bCoords[3], float3 edges){
	float3 xCoord = float3(1,0,0);
	float3 yCoord = float3(0,1,0);
	float3 zCoord = float3(0,0,1);

	if (_WFMode == 1){
		float3 pat = 0;
		if (edges.x > edges.y && edges.x > edges.z)
			pat.y = 1;
		else if (edges.y > edges.z && edges.y > edges.x)
			pat.x = 1;
		else
			pat.z = 1;
		xCoord = float3(1,0,0) + pat;
		yCoord = float3(0,0,1) + pat;
		zCoord = float3(0,1,0) + pat;
	}

	bCoords[0] = xCoord;
	bCoords[1] = yCoord;
	bCoords[2] = zCoord;
}

float GetWireframeStrength(inout float3 bCoords, float3 bCoordsN, float shatterAmt, float dist){
	if (_ShatterToggle == 1){
		float interpolator = smoothstep(_ShatterMax, _ShatterMin*_PatternMult, dist);
		bCoords = lerp(bCoords, bCoordsN, interpolator);
	}
	float wfStr = _WFVisibility;
	if (shatterAmt > 0)
		wfStr = smoothstep(0, 1, shatterAmt*50);
	return wfStr;
}

//----------------------------
// Fragment Shader
//----------------------------
#if NON_OPAQUE_RENDERING
void GetFalloff(g2f i, out float falloff, out float falloffRim){
	falloff = 0;
	falloffRim = 0;
	#if CLONES_ENABLED
		UNITY_BRANCH
		if (_DFClones == 1){
			if (i.instID != 0){
				UNITY_BRANCH
				if (_DistanceFadeToggle == 1){
					float dist = distance(i.cameraPos, i.worldPos);
					float rimWidth = _DistanceFadeMin-(0.025*abs(_ClipRimWidth));
					falloff = -step(_DistanceFadeMin, dist);
					falloffRim = linearstep(_DistanceFadeMin, rimWidth, dist);
				}
				else if (_DistanceFadeToggle == 2) {
					float dist = distance(i.cameraPos, i.worldPos);
					float noise = GetNoise(i.uv.xy);
					falloff = linearstep(_DistanceFadeMax, clamp(_DistanceFadeMin, 0, _DistanceFadeMax-0.001), dist);
					falloff = -step(falloff, noise);
				}
			}
		}
		else {
			UNITY_BRANCH
			if (_DistanceFadeToggle == 1){
				float dist = distance(i.cameraPos, i.worldPos);
				float rimWidth = _DistanceFadeMin-(0.025*abs(_ClipRimWidth));
				falloff = -step(_DistanceFadeMin, dist);
				falloffRim = linearstep(_DistanceFadeMin, rimWidth, dist);
			}
			else if (_DistanceFadeToggle == 2) {
				float dist = distance(i.cameraPos, i.worldPos);
				float noise = GetNoise(i.uv.xy);
				falloff = linearstep(_DistanceFadeMax, clamp(_DistanceFadeMin, 0, _DistanceFadeMax-0.001), dist);
				falloff = -step(falloff, noise);
			}
		}
	#else
		UNITY_BRANCH
		if (_DistanceFadeToggle == 1){
			float dist = distance(i.cameraPos, i.worldPos);
			float rimWidth = _DistanceFadeMin-(0.025*abs(_ClipRimWidth));
			falloff = -step(_DistanceFadeMin, dist);
			falloffRim = linearstep(_DistanceFadeMin, rimWidth, dist);
		}
		else if (_DistanceFadeToggle == 2) {
			float dist = distance(i.cameraPos, i.worldPos);
			float noise = GetNoise(i.uv.xy);
			falloff = linearstep(_DistanceFadeMax, clamp(_DistanceFadeMin, 0, _DistanceFadeMax-0.001), dist);
			falloff = -step(falloff, noise);
		}
	#endif
}

void ApplyFalloffRim(g2f i, inout float3 diffuse, float rim){
	if (_DistanceFadeToggle == 1){
		diffuse = lerp(_ClipRimColor.rgb, diffuse, saturate(pow(rim,_ClipRimStr)));
	}
}

float GetSimplex4D(float3 coords){
	float4 c = float4(coords * _DissolveNoiseScale, _Time.y*_DissolveBlendSpeed);
	float n = 0;
	float a = 0.5;

	[unroll(2)]
	for (int i = 0; i < 2; i++){
		n += a*Simplex4D(c);
		c = c * 2 + float(i)*0.01;
		a *= 0.5;
	}
	
	return (n + 1) * 0.5;
}

float3 GetDissolveMapping(g2f i){
	#if DISSOLVE_TEXTURE
		UNITY_BRANCH
		if (_DissolveBlending == 1){
			float flowMap = MOCHIE_SAMPLE_TEX2D_SAMPLER(_DissolveFlow, sampler_MainTex, i.uv1.xy).a;
			float time = _Time.y * _DissolveBlendSpeed + flowMap;
			float3 uv0 = FlowUV(i.uv1.xy, time, 0.75);
			float3 uv1 = FlowUV(i.uv1.xy*1.7533, time, 0.25);
			float4 tex0 = MOCHIE_SAMPLE_TEX2D_SAMPLER(_DissolveTex, sampler_MainTex, uv0.xy) * uv0.z;
			float4 tex1 = MOCHIE_SAMPLE_TEX2D_SAMPLER(_DissolveTex, sampler_MainTex, uv1.xy) * uv1.z;
			float3 tex = tex0.rgb + tex1.rgb;
			return tex;
		}
		else {
			return MOCHIE_SAMPLE_TEX2D_SAMPLER(_DissolveTex, sampler_MainTex, i.uv1.xy).rgb;
		}
	#elif DISSOLVE_SIMPLEX
		return GetSimplex4D(i.localPos);
	#endif
	return 0;
}

float GetDissolveValue(g2f i){
	float3 noise = GetDissolveMapping(i);
	return lerp(1, noise.r, MOCHIE_SAMPLE_TEX2D_SAMPLER(_DissolveMask, sampler_MainTex, i.uv.xy).r);
}

void ApplyDissolveRim(g2f i, audioLinkData al, inout float3 diffuse){
	#if AUDIOLINK_ENABLED
		float dissolveValueAL = GetAudioLinkBand(al, _AudioLinkDissolveBand, _AudioLinkRemapDissolveMin, _AudioLinkRemapDissolveMax);
		_DissolveAmount *= lerp(1, dissolveValueAL, _AudioLinkDissolveMultiplier*_AudioLinkStrength);
	#endif
	#if CLONES_ENABLED
		#if DISSOLVE_ENABLED
			UNITY_BRANCH
			if (_DissolveClones){
				if (i.instID != 0){
					float noise = GetDissolveValue(i);
					float dissolveStr = noise - _DissolveAmount;
					clip(dissolveStr);
					diffuse += step(dissolveStr, _DissolveRimWidth*0.035) * _DissolveRimCol;
				}
			}
			else {
				float noise = GetDissolveValue(i);
				float dissolveStr = noise - _DissolveAmount;
				clip(dissolveStr);
				diffuse += step(dissolveStr, _DissolveRimWidth*0.035) * _DissolveRimCol;
			}
		#endif
	#else
		#if DISSOLVE_ENABLED
			float noise = GetDissolveValue(i);
			float dissolveStr = noise - _DissolveAmount;
			clip(dissolveStr);
			diffuse += step(dissolveStr, _DissolveRimWidth*0.035) * _DissolveRimCol;
		#endif
	#endif
}
#endif // NON_OPAQUE_RENDERING

void ApplyWireframe(g2f i, inout float4 diffuse){
	#if CLONES_ENABLED
		UNITY_BRANCH
		if (_WFClones == 1){
			if (i.instID != 0){
				i.bCoords = smoothstep(0, fwidth(i.bCoords), i.bCoords);
				float minBary = min(i.bCoords.x, min(i.bCoords.y, i.bCoords.z));
				float3 wfCol = lerp(_WFColor.rgb, diffuse.rgb, minBary);
				diffuse.rgb = lerp(diffuse.rgb, wfCol, i.WFStr);
				diffuse.rgb = lerp(diffuse.rgb, _WFColor.rgb, i.wfOpac * i.WFStr);
				#if TRANSPARENT_RENDERING
					if (_WireframeTransparency == 1){
						diffuse.a = (1-minBary) + i.wfOpac;
					}
				#endif
			}
		}
		else {
			i.bCoords = smoothstep(0, fwidth(i.bCoords), i.bCoords);
			float minBary = min(i.bCoords.x, min(i.bCoords.y, i.bCoords.z));
			float3 wfCol = lerp(_WFColor.rgb, diffuse.rgb, minBary);
			diffuse.rgb = lerp(diffuse.rgb, wfCol, i.WFStr);
			diffuse.rgb = lerp(diffuse.rgb, _WFColor.rgb, i.wfOpac * i.WFStr);
			#if TRANSPARENT_RENDERING
				if (_WireframeTransparency == 1){
					diffuse.a = (1-minBary) + i.wfOpac;
				}
			#endif
		}
	#else
		if (_WireframeToggle == 1){
			i.bCoords = smoothstep(0, fwidth(i.bCoords), i.bCoords);
			float minBary = min(i.bCoords.x, min(i.bCoords.y, i.bCoords.z));
			float3 wfCol = lerp(_WFColor.rgb, diffuse.rgb, minBary);
			diffuse.rgb = lerp(diffuse.rgb, wfCol, i.WFStr);
			diffuse.rgb = lerp(diffuse.rgb, _WFColor.rgb, i.wfOpac * i.WFStr);
			#if TRANSPARENT_RENDERING
				if (_WireframeTransparency == 1){
					diffuse.a = (1-minBary) + i.wfOpac;
				}
			#endif
		}
	#endif
}

void ApplyAudioLinkWireframe(g2f i, inout float4 diffuse){
	#if AUDIOLINK_ENABLED
		i.bCoords = smoothstep(0, fwidth(i.bCoords), i.bCoords);
		float minBary = min(i.bCoords.x, min(i.bCoords.y, i.bCoords.z));
		float3 wfCol = lerp(_AudioLinkWireframeColor.rgb, diffuse.rgb, minBary);
		diffuse.rgb = lerp(diffuse.rgb, wfCol, i.wfStrAL * _AudioLinkWireframeColor.a);
		diffuse.rgb = lerp(diffuse.rgb, _AudioLinkWireframeColor.rgb, i.wfOpacAL * i.wfStrAL * _AudioLinkWireframeColor.a);
	#endif
}

#endif // X_FEATURES