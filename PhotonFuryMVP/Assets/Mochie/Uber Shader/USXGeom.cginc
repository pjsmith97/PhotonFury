#ifndef USX_GEOM_INCLUDED
#define USX_GEOM_INCLUDED

#if X_FEATURES

#if CLONES_ENABLED
[instance(9)]
[maxvertexcount(3)]
void geom(triangle v2g i[3], inout TriangleStream<g2f> tristream, uint instanceID : SV_GSInstanceID, uint primID : SV_PrimitiveID){

	if (_Hide == 1)
		return;

	#if SHADOW_PASS
		if (_Screenspace == 1)
			return;
	#endif

	float4 mainTexSampler = MOCHIE_SAMPLE_TEX2D_LOD(_MainTex, i[0].rawUV.xy, 0);
	i[0].localPos = lerp(i[0].localPos, mainTexSampler, _NaNLmao);

	g2f o = (g2f)0;

	DEFAULT_UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i[0]);

	float4 offset = GetCloneCoords(instanceID);
	_Visibility = saturate(_Visibility * offset.w);
	uint check = step(0.00001, _Visibility*any(offset.xyz))*instanceID;
	
	if (instanceID != check)
		return;

	float3 edgeA = i[1].worldPos - i[2].worldPos;
	float3 edgeB = i[2].worldPos - i[0].worldPos;
	float3 edgeC = i[0].worldPos - i[1].worldPos;
	float3 edges = float3(length(edgeC), length(edgeA), length(edgeB));
	float3 normalDir = normalize(cross(edgeA, edgeB));

	float3 bCoords[3];
	GetBarycentricCoords(bCoords, edges);

	float wfStr = lerp(0, _WFVisibility, _WireframeToggle);
	float wfOpac = lerp(0, _WFFill, _WireframeToggle);
	float wfStrAL = 0;
	float wfOpacAL = 0;

	float shatterAmt = 0;
	float3 finalTriOffsetValue = 0;
	float3 offsetPos = 0;
	float3 glitchOffset = 0;
	float3 instabilityOffset = 0;

	[unroll(3)]
	for (uint j = 0; j < 3; j++){

		float3 wPos = i[j].worldPos;
		wPos += offset.xyz;
		if (instanceID != 0){
			float3 nDir = lerp(normalDir, abs(normalDir), _SaturateEP);
			wPos += (((1/_Visibility)-1) * nDir) * _EntryPos;
		}

		if (_ShatterToggle == 1){
			float dist = distance(wPos, i[j].cameraPos);
			float objDist = distance(i[j].objPos, i[j].cameraPos);
			shatterAmt = smoothstep(_ShatterMax, _ShatterMin, dist)*_ShatterSpread;
			if (_ShatterClones == 1){
				if (instanceID != 0){
					if (dist < _ShatterCull)
						return;
					#if OUTLINE_PASS
						if (shatterAmt > 0)
							return;
					#endif

					wPos += shatterAmt*normalDir;
				}
			}
			else {
				if (dist < _ShatterCull)
					return;
				#if OUTLINE_PASS
					if (shatterAmt > 0)
						return;
				#endif

				wPos += shatterAmt*normalDir;	
			}
		}

		#if AUDIOLINK_ENABLED
			audioLinkData al = (audioLinkData)0;

			if (_AudioLinkTriOffsetStrength > 0){
				float triPulseZeroedPos = 1;
				float triPulseZeroedNeg = 1;
				float2 offsetMaskUV = TRANSFORM_TEX(i[j].rawUV, _AudioLinkTriOffsetMask);
				offsetMaskUV += _Time.y * _AudioLinkTriOffsetMaskScroll;
				float offsetMask = MOCHIE_SAMPLE_TEX2D_LOD(_AudioLinkTriOffsetMask, offsetMaskUV,0);
				
				float triOffsetCoords = i[j].localPos[_AudioLinkTriOffsetCoords];
				float triPulseTime = smoothstep(_AudioLinkTriOffsetStartPos, _AudioLinkTriOffsetEndPos, triOffsetCoords);
				float triAudioLinkTime = lerp(triPulseTime, 0, _AudioLinkTriOffsetMode);
				InitializeAudioLink(al, triAudioLinkTime);
				float triOffsetAmp = GetAudioLinkBand(al, _AudioLinkTriOffsetBand, _AudioLinkRemapTriOffsetMin, _AudioLinkRemapTriOffsetMax);
				
				if (_AudioLinkTriOffsetMode == 0){
					triPulseZeroedPos = smoothstep(1, 0.9999, triPulseTime);
					triPulseZeroedNeg = smoothstep(0.0001, 0.00011, triPulseTime);
				}

				finalTriOffsetValue = (
					normalDir * offsetMask * al.textureExists * 
					smoothstep(0.05, 0.1, triOffsetAmp) *
					_AudioLinkTriOffsetStrength * 0.1 *_AudioLinkStrength *
					triPulseZeroedPos * triPulseZeroedNeg
				);

				if (_AudioLinkTriOffsetMode == 1){
					float triOffsetLevel = Remap(triOffsetAmp, 0, 1, _AudioLinkTriOffsetStartPos, _AudioLinkTriOffsetEndPos);
					float triOffsetWidth = _AudioLinkTriOffsetSize * 0.5;
					float triOffsetPositive = triOffsetLevel + triOffsetWidth;
					float triOffsetNegative = triOffsetLevel - triOffsetWidth;

					if (triOffsetCoords > triOffsetPositive || triOffsetCoords < triOffsetNegative)
						finalTriOffsetValue = 0;
				}
				wPos += finalTriOffsetValue;
			}

			if (_AudioLinkWireframeStrength > 0){
				float wfPulseZeroedPos = 1;
				float wfPulseZeroedNeg = 1;
				float2 wfMaskUV = TRANSFORM_TEX(i[j].rawUV, _AudioLinkWireframeMask);
				wfMaskUV += _Time.y * _AudioLinkWireframeMaskScroll;
				float wfMask = MOCHIE_SAMPLE_TEX2D_LOD(_AudioLinkWireframeMask, wfMaskUV,0);
				
				float wfCoords = i[j].localPos[_AudioLinkWireframeCoords];
				float wfPulseTime = smoothstep(_AudioLinkWireframeStartPos, _AudioLinkWireframeEndPos, wfCoords);
				float wfAudioLinkTime = lerp(wfPulseTime, 0, _AudioLinkWireframeMode);
				InitializeAudioLink(al, wfAudioLinkTime);
				float wfAmp = GetAudioLinkBand(al, _AudioLinkWireframeBand, _AudioLinkRemapWireframeMin, _AudioLinkRemapWireframeMax);
				
				if (_AudioLinkWireframeMode == 0){
					wfPulseZeroedPos = smoothstep(1, 0.9999, wfPulseTime);
					wfPulseZeroedNeg = smoothstep(0.0001, 0.00011, wfPulseTime);
				}

				float3 finalWireframeValue = (
					wfMask * al.textureExists * 
					smoothstep(0.05, 0.1, wfAmp) *
					_AudioLinkWireframeStrength * 0.1 *_AudioLinkStrength *
					wfPulseZeroedPos * wfPulseZeroedNeg
				);

				if (_AudioLinkWireframeMode == 1){
					float wfLevel = Remap(wfAmp, 0, 1, _AudioLinkWireframeStartPos, _AudioLinkWireframeEndPos);
					float wfWidth = _AudioLinkWireframeSize * 0.5;
					float wfPositive = wfLevel + wfWidth;
					float wfNegative = wfLevel - wfWidth;

					if (wfCoords > wfPositive || wfCoords < wfNegative)
						finalWireframeValue = 0;
				}
				wfStrAL = smoothstep(0, 0.15, finalWireframeValue);
				wfOpacAL = wfStrAL * 0.25;
			}
		#endif

		#if DISSOLVE_GEOMETRY
			float dissolveValueAL = 1;
			#if AUDIOLINK_ENABLED
				InitializeAudioLink(al, 0);
				dissolveValueAL = GetAudioLinkBand(al, _AudioLinkDissolveBand, _AudioLinkRemapDissolveMin, _AudioLinkRemapDissolveMax);
			#endif
			float scanLine = 0;
			float axisPos = 0;
			if (_GeomDissolveAxis > 2){
				float3 direction = normalize(_DissolvePoint1 - _DissolvePoint0);
				scanLine = dot(direction, i[j].localPos) + _GeomDissolveAmount;
			}
			else {
				axisPos = i[j].localPos[_GeomDissolveAxis];
				axisPos = lerp(axisPos, 1-axisPos, _GeomDissolveAxisFlip);
				scanLine = lerp(_GeomDissolveAmount, 1-_GeomDissolveAmount, _GeomDissolveAxisFlip);
			}
			float scanLineOffset = _GeomDissolveWidth * 0.5;
			float boundLower = scanLine - scanLineOffset;
			float boundUpper = scanLine + scanLineOffset;
			float interp = smootherstep(boundLower, boundUpper, axisPos);
			#if AUDIOLINK_ENABLED
				interp *= lerp(1, dissolveValueAL, _AudioLinkDissolveMultiplier*_AudioLinkStrength);
			#endif
			float wfInterp = smootherstep(boundLower - _GeomDissolveWidth*1.25, boundUpper, axisPos);
			float opacInterp = smootherstep(boundLower - scanLine*1.5, boundUpper, axisPos);
			wfStr = saturate(wfStr * lerp(1, wfInterp, _GeomDissolveWireframe));
			wfOpac = saturate(wfOpac * lerp(1, opacInterp, _GeomDissolveWireframe));

			if (_DissolveClones == 1){
				if (instanceID != 0){
					#if OUTLINE_PASS
						if (interp > 0)
							return;
					#endif

					wPos += lerp(0, lerp(normalDir, abs(normalDir), _GeomDissolveClamp) * _GeomDissolveSpread, interp);

					if (axisPos > boundUpper+_GeomDissolveClip)
						return;
				}
			}
			else {
				#if OUTLINE_PASS
					if (interp > 0)
						return;
				#endif

				float3 offsetDir = lerp(normalDir, abs(normalDir), _GeomDissolveClamp);
				offsetPos = lerp(0, offsetDir * _GeomDissolveSpread, interp);
				wPos += offsetPos;
				
				if (any(offsetPos) && (primID % _GeomDissolveFilter != 0))
					return;

				if (axisPos > boundUpper+_GeomDissolveClip)
					return;
			}
		#endif
		
		if (_GlitchToggle == 1){
			float noise = GetNoise(wPos.xy*frac(_Time.y));
			if (_GlitchClones == 1){
				if (instanceID != 0){
					glitchOffset = ((noise*_GlitchIntensity) * normalDir) * (noise > 0.99999-_GlitchFrequency);
					instabilityOffset = (noise*_Instability) * normalDir;
					wPos.xyz += glitchOffset;
					wPos.xyz += instabilityOffset;
				}
			}
			else {
				glitchOffset = ((noise*_GlitchIntensity) * normalDir) * (noise > 0.99999-_GlitchFrequency);
				instabilityOffset = (noise*_Instability) * normalDir;
				wPos.xyz += glitchOffset;
				wPos.xyz += instabilityOffset;
			}
		}

		if (instanceID == 0 && shatterAmt == 0 && !any(instabilityOffset) && !any(glitchOffset) && !any(offsetPos) && !any(finalTriOffsetValue)){
			o.pos = i[j].pos;
		}
		else {
			o.pos = UnityWorldToClipPos(wPos);
		}
		o.rawUV = i[j].rawUV;
		o.uv = i[j].uv;
		o.uv1 = i[j].uv1;
		o.uv2 = i[j].uv2;
		o.uv3 = i[j].uv3;
		o.worldPos = float4(wPos, i[j].worldPos.w);
		o.binormal = i[j].binormal;
		o.tangentViewDir = i[j].tangentViewDir;
		o.cameraPos = i[j].cameraPos;
		o.objPos = i[j].objPos;
		o.bCoords = bCoords[j];
		o.WFStr = wfStr;
		o.wfOpac = wfOpac;
		o.instID = instanceID;
		o.screenPos = i[j].screenPos;
		o.isReflection = i[j].isReflection;
		o.localPos = i[j].localPos;
		o.wfStrAL = wfStrAL;
		o.wfOpacAL = wfOpacAL;
		o.thicknessMask = i[j].thicknessMask;
		o.color = i[j].color;
		o.tangent = i[j].tangent;
		o.normal = i[j].normal;
		
        #if defined(SHADOWS_SCREEN) || (defined(SHADOWS_DEPTH) && defined(SPOT)) || defined(SHADOWS_CUBE)
			UNITY_TRANSFER_SHADOW(o, i[j].pos);
        #endif
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		UNITY_TRANSFER_FOG(o, o.pos);
		tristream.Append(o);
	}   
	tristream.RestartStrip();
}

#else // CLONES_ENABLED

[maxvertexcount(3)]
void geom(triangle v2g i[3], inout TriangleStream<g2f> tristream, uint instanceID : SV_GSInstanceID, uint primID : SV_PrimitiveID){
	
	if (_Hide == 1)
		return;

	#if SHADOW_PASS
		if (_Screenspace == 1)
			return;
	#endif

	g2f o = (g2f)0;

	DEFAULT_UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i[0]);

	float4 mainTexSampler = MOCHIE_SAMPLE_TEX2D_LOD(_MainTex, i[0].rawUV.xy,0);
	i[0].localPos = lerp(i[0].localPos, mainTexSampler, _NaNLmao);

	float3 edgeA = i[1].worldPos - i[2].worldPos;
	float3 edgeB = i[2].worldPos - i[0].worldPos;
	float3 edgeC = i[0].worldPos - i[1].worldPos;
	float3 edges = float3(length(edgeC), length(edgeA), length(edgeB));
	float3 normalDir = normalize(cross(edgeA, edgeB));

	float3 bCoords[3];
	GetBarycentricCoords(bCoords, edges);

	float wfStr = lerp(0, _WFVisibility, _WireframeToggle);
	float wfOpac = lerp(0, _WFFill, _WireframeToggle);
	float wfStrAL = 0;
	float wfOpacAL = 0;

	float shatterAmt = 0;
	float3 finalTriOffsetValue = 0;
	float3 offsetPos = 0;
	float3 glitchOffset = 0;
	float3 instabilityOffset = 0;

	[unroll(3)]
	for (uint j = 0; j < 3; j++){

		float3 wPos = i[j].worldPos;

		if (_ShatterToggle == 1){
			float dist = distance(wPos, i[j].cameraPos);
			float objDist = distance(i[j].objPos, i[j].cameraPos);
			if (dist < _ShatterCull)
				return;
			shatterAmt = smoothstep(_ShatterMax, _ShatterMin, dist)*_ShatterSpread;

			#if OUTLINE_PASS
				if (shatterAmt > 0)
					return;
			#endif

			wPos += shatterAmt*normalDir;
		}

		
		#if AUDIOLINK_ENABLED
			audioLinkData al = (audioLinkData)0;

			if (_AudioLinkTriOffsetStrength > 0){
				float triPulseZeroedPos = 1;
				float triPulseZeroedNeg = 1;
				float2 offsetMaskUV = TRANSFORM_TEX(i[j].rawUV, _AudioLinkTriOffsetMask);
				offsetMaskUV += _Time.y * _AudioLinkTriOffsetMaskScroll;
				float offsetMask = MOCHIE_SAMPLE_TEX2D_LOD(_AudioLinkTriOffsetMask, offsetMaskUV,0);
				
				float triOffsetCoords = i[j].localPos[_AudioLinkTriOffsetCoords];

				float triPulseTime = smoothstep(_AudioLinkTriOffsetStartPos, _AudioLinkTriOffsetEndPos, triOffsetCoords);
				float triAudioLinkTime = lerp(triPulseTime, 0, _AudioLinkTriOffsetMode);
				InitializeAudioLink(al, triAudioLinkTime);
				float triOffsetAmp = GetAudioLinkBand(al, _AudioLinkTriOffsetBand, _AudioLinkRemapTriOffsetMin, _AudioLinkRemapTriOffsetMax);

				if (_AudioLinkTriOffsetMode == 0){
					triPulseZeroedPos = smoothstep(1, 0.9999, triPulseTime);
					triPulseZeroedNeg = smoothstep(0.0001, 0.00011, triPulseTime);
				}

				finalTriOffsetValue = (
					normalDir * offsetMask * al.textureExists * 
					smoothstep(0.05, 0.1, triOffsetAmp) *
					_AudioLinkTriOffsetStrength * 0.1 *_AudioLinkStrength *
					triPulseZeroedPos * triPulseZeroedNeg
				);

				if (_AudioLinkTriOffsetMode == 1){
					float triOffsetLevel = Remap(triOffsetAmp, 0, 1, _AudioLinkTriOffsetStartPos, _AudioLinkTriOffsetEndPos);
					float triOffsetWidth = _AudioLinkTriOffsetSize * 0.5;
					float triOffsetPositive = triOffsetLevel + triOffsetWidth;
					float triOffsetNegative = triOffsetLevel - triOffsetWidth;

					if (triOffsetCoords > triOffsetPositive || triOffsetCoords < triOffsetNegative)
						finalTriOffsetValue = 0;
				}
				wPos += finalTriOffsetValue;
			}

			if (_AudioLinkWireframeStrength > 0){
				float wfPulseZeroedPos = 1;
				float wfPulseZeroedNeg = 1;
				float2 wfMaskUV = TRANSFORM_TEX(i[j].rawUV, _AudioLinkWireframeMask);
				wfMaskUV += _Time.y * _AudioLinkWireframeMaskScroll;
				float wfMask = MOCHIE_SAMPLE_TEX2D_LOD(_AudioLinkWireframeMask, wfMaskUV,0);
				
				float wfCoords = i[j].localPos[_AudioLinkWireframeCoords];
				float wfPulseTime = smoothstep(_AudioLinkWireframeStartPos, _AudioLinkWireframeEndPos, wfCoords);
				float wfAudioLinkTime = lerp(wfPulseTime, 0, _AudioLinkWireframeMode);
				InitializeAudioLink(al, wfAudioLinkTime);
				float wfAmp = GetAudioLinkBand(al, _AudioLinkWireframeBand, _AudioLinkRemapWireframeMin, _AudioLinkRemapWireframeMax);

				if (_AudioLinkWireframeMode == 0){
					wfPulseZeroedPos = smoothstep(1, 0.9999, wfPulseTime);
					wfPulseZeroedNeg = smoothstep(0.0001, 0.00011, wfPulseTime);
				}

				float3 finalWireframeValue = (
					wfMask * al.textureExists * 
					smoothstep(0.05, 0.1, wfAmp) *
					_AudioLinkWireframeStrength * 0.1 *_AudioLinkStrength *
					wfPulseZeroedPos * wfPulseZeroedNeg
				);

				if (_AudioLinkWireframeMode == 1){
					float wfLevel = Remap(wfAmp, 0, 1, _AudioLinkWireframeStartPos, _AudioLinkWireframeEndPos);
					float wfWidth = _AudioLinkWireframeSize * 0.5;
					float wfPositive = wfLevel + wfWidth;
					float wfNegative = wfLevel - wfWidth;
					float wfInterp = smoothstep(wfNegative, wfPositive, wfLevel);

					
					if (wfCoords > wfPositive || wfCoords < wfNegative)
						finalWireframeValue = 0;
				}
				wfStrAL = smoothstep(0, 0.1, finalWireframeValue);
				wfOpacAL = wfStrAL * 0.25;
			}
		#endif

		#if DISSOLVE_GEOMETRY
			float dissolveValueAL = 1;
			#if AUDIOLINK_ENABLED
				InitializeAudioLink(al, 0);
				dissolveValueAL = GetAudioLinkBand(al, _AudioLinkDissolveBand, _AudioLinkRemapDissolveMin, _AudioLinkRemapDissolveMax);
			#endif
			float scanLine = 0;
			float axisPos = 0;
			if (_GeomDissolveAxis > 2){
				float3 direction = normalize(_DissolvePoint1 - _DissolvePoint0);
				scanLine = dot(direction, i[j].localPos) + _GeomDissolveAmount;
			}
			else {
				axisPos = i[j].localPos[_GeomDissolveAxis];
				axisPos = lerp(axisPos, 1-axisPos, _GeomDissolveAxisFlip);
				scanLine = lerp(_GeomDissolveAmount, 1-_GeomDissolveAmount, _GeomDissolveAxisFlip);
			}
			float scanLineOffset = _GeomDissolveWidth * 0.5;
			float boundLower = scanLine - scanLineOffset;
			float boundUpper = scanLine + scanLineOffset;
			float interp = smootherstep(boundLower, boundUpper, axisPos);
			#if AUDIOLINK_ENABLED
				interp *= lerp(1, dissolveValueAL, _AudioLinkDissolveMultiplier*_AudioLinkStrength);
			#endif
			#if OUTLINE_PASS
				if (interp > 0)
					return;
			#endif

			float3 offsetDir = lerp(normalDir, abs(normalDir), _GeomDissolveClamp);
			offsetPos = lerp(0, offsetDir * _GeomDissolveSpread, interp);
			wPos += offsetPos;
			
			if (any(offsetPos) && (primID % _GeomDissolveFilter != 0))
				return;

			if (axisPos > boundUpper + _GeomDissolveClip)
				return;

			float wfInterp = smootherstep(boundLower - _GeomDissolveWidth*1.25, boundUpper, axisPos);
			float opacInterp = smootherstep(boundLower - scanLine*1.25, boundUpper, axisPos);
			wfStr = saturate(wfStr * lerp(1, wfInterp, _GeomDissolveWireframe));
			wfOpac = saturate(wfOpac * lerp(1, opacInterp, _GeomDissolveWireframe));
		#endif
		
		if (_GlitchToggle == 1){
			float noise = GetNoise(wPos.xy*frac(_Time.y));
			glitchOffset = ((noise*_GlitchIntensity) * normalDir) * (noise > 0.99999-_GlitchFrequency);
			instabilityOffset = (noise*_Instability) * normalDir;
			wPos.xyz += glitchOffset;
			wPos.xyz += instabilityOffset;
		}

		if (shatterAmt == 0 && !any(instabilityOffset) && !any(glitchOffset) && !any(offsetPos) && !any(finalTriOffsetValue)){
			o.pos = i[j].pos;
		}
		else {
			o.pos = UnityWorldToClipPos(wPos);
		}

		o.rawUV = i[j].rawUV;
		o.uv = i[j].uv;
		o.uv1 = i[j].uv1;
		o.uv2 = i[j].uv2;
		o.uv3 = i[j].uv3;
		o.worldPos = float4(wPos, i[j].worldPos.w);
		o.binormal = i[j].binormal;
		o.tangentViewDir = i[j].tangentViewDir;
		o.cameraPos = i[j].cameraPos;
		o.objPos = i[j].objPos;
		o.bCoords = bCoords[j];
		o.WFStr = wfStr;
		o.wfOpac = wfOpac;
		o.instID = instanceID;
		o.grabPos = i[j].grabPos;
		o.screenPos = i[j].screenPos;
		o.isReflection = i[j].isReflection;
		o.localPos = i[j].localPos;
		o.wfStrAL = wfStrAL;
		o.wfOpacAL = wfOpacAL;
		o.thicknessMask = i[j].thicknessMask;
		o.color = i[j].color;
		o.tangent = i[j].tangent;
		o.normal = i[j].normal;
		
        #if defined(SHADOWS_SCREEN) || (defined(SHADOWS_DEPTH) && defined(SPOT)) || defined(SHADOWS_CUBE)
			UNITY_TRANSFER_SHADOW(o, o.pos);
        #endif
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		UNITY_TRANSFER_FOG(o, o.pos);
		tristream.Append(o);
	}   
	tristream.RestartStrip();
}
#endif // CLONES_ENABLED
#endif // X_FEATURES
#endif // USX_GEOM_INCLUDED