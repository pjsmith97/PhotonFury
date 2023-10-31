// By Mochie
Shader "Mochie/Taken" {
    Properties {

        // [Header(BASE SETTINGS)]
		[Enum(Opaque,0, Cutout,1, Dithered,2, Fade,3, Transparent,4)]_BlendMode("Blend Mode", Int) = 0.0
		[HideInInspector]_SrcBlend("__src", Float) = 1.0
		[HideInInspector]_DstBlend ("__dst", Float) = 0.0
		[Enum(Off,0, On,1)]_ATM("", Int) = 0
		[Enum(Off,0, On,1)]_ZWrite("", Int) = 1
		_Cutoff("Cutout", Range(0,1)) = 0.5
		_Color("Global Tint", Color) = (0.8,0.95,1,1)
		[ToggleUI]_Invert("Invert", Int) = 0
		[ToggleUI]_Smoothstep("Smoothstep", Int) = 0
		[Enum(Off,0, Front,1, Back,2)]_Culling("Culling", Int) = 2
		_MainTex("Main Texture", 2D) = "black" {}
		[NoScaleOffset]_EmissTex("Ambient Occlusion", 2D) = "black" {}
		_BumpScale("Normal Strength", Float) = 1
		[NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}

		// [Header(LIGHTING)]
		[ToggleUI]_EnableLighting("Enable", Int) = 1
		[ToggleUI]_EnableSH("Spherical Harmonics", Int) = 0
		[ToggleUI]_EnableReflections("Reflections", Int) = 0
		_Metallic("Metallic", Range(0,1)) = 0
		_Roughness("Roughness", Range(0,1)) = 1
		_ReflectionStr("Reflections", Range(0,1)) = 1
		[NoScaleOffset]_MetallicMap("Metallic Map", 2D) = "white" {}
		[NoScaleOffset]_RoughnessMap("Roughness Map", 2D) = "white" {}
		[NoScaleOffset]_ReflectionMask("Reflection Mask", 2D) = "white" {}

		// [Header(RIM LIGHT)]
		[ToggleUI]_EnableRim("Enable", Int) = 1
		_RimBrightness("Strength", Float) = 1
		_RimWidth("Width", Range(0,1)) = 0.5
		_RimEdge("Sharpness", Range(0,0.5)) = 0
		_RimGradMask("Gradient Restriction", Range(0,1)) = 1
		[NoScaleOffset]_RimMask("Mask", 2D) = "white" {}

		// [Header(EMISSION)]
		[ToggleUI]_EmissInvert("Invert", Int) = 1
		_EmissStr("Strength", Float) = 1
		_EmissPow("Exponent", Float) = 1
		_EmissGradMasking("Gradient Restriction", Range(0,1)) = 0.99
		[NoScaleOffset]_EmissGradMask("Restriction Mask", 2D) = "white" {}

		// [Header(GRADIENT)]
		[ToggleUI]_EnableGradient("Enable", Int) = 1
		[ToggleUI]_GradientInvert("Invert Axis", Int) = 0
		[Enum(X,0, Y,1, Z,2)]_GradientAxis("Axis", Int) = 1
		_GradientNoiseScale("Noise Scale", Vector) = (5,5,5,0)
		_GradientBrightness("Brightness", Float) = 1
		_GradientHeightMax("Top Position", Float) = 0
		_GradientHeightMin("Bottom Position", Float) = -1
		_GradientSpeed("Scroll Speed", Float) = 0.01
		_GradientContrast("Contrast", Range(0,2)) = 1.5
		[NoScaleOffset]_GradientMask("Mask", 2D) = "white" {}

		// [Header(NOISE PATCHES)]
		[ToggleUI]_EnablePatches("Enable", Int) = 1
		_NoiseScale("Scale", Vector) = (50,50,0,0)
		_NoiseBrightness("Brightness", Float) = 1
		_NoiseCutoff("Cutoff", Range(0,1)) = 0.73
		_NoiseSmooth("Smoothing", Range(0,0.1)) = 0.01
		[NoScaleOffset]_NoiseMask("Mask", 2D) = "white" {}

		// [Header(DISSOLVE)]
		[ToggleUI]_EnableDissolve("Enable", Int) = 0
		_DissolveTex("Dissolve Texture (Alpha)", 2D) = "white" {}
		_DissolveAmt("Dissolve Amount", Range(0,1)) = 0
		_DissolveRimBrightness("Rim Brightness", Float) = 1
		_DissolveRimWidth("Rim Width", Float) = 2

		// [Header(OUTLINE)]
		[ToggleUI]_EnableOutline("Enable", Int) = 0
		[ToggleUI]_InvertedOutline("Inverted Tint", Int) = 1
		[ToggleUI]_StencilOutline("Stencil Mode", Int) = 0
		_Thickness("Thickness", Float) = 0.1
		[NoScaleOffset]_OutlineMask("Mask", 2D) = "white" {}

		[IntRange]_StencilRef("ra", Range(1,255)) = 1
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass("enx", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilFail("emx", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilZFail("enx", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilCompare("enx", Float) = 8
		[Enum(UnityEngine.Rendering.StencilOp)]_OutlineStencilPass("enx", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_OutlineStencilCompare("enx", Float) = 8
		[Enum(Off,0, Front,1, Back,2)]_OutlineCulling("Culling", Int) = 1

    }

    SubShader {
        Tags {"RenderType"="Opaque" "Queue"="Geometry"}
        Cull [_Culling]
		ZWrite [_ZWrite]
		AlphaToMask [_ATM]
		Blend [_SrcBlend] [_DstBlend]

        Pass {
			Stencil {
                Ref [_StencilRef]
                Comp [_StencilCompare]
                Pass [_StencilPass]
                Fail [_StencilFail]
                ZFail [_StencilZFail]
            }
            Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHADITHER_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local _LIGHTING_ON
			#pragma shader_feature_local _REFLECTIONS_ON
			#pragma shader_feature_local _RIM_ON
			#pragma shader_feature_local _GRADIENT_ON
			#pragma shader_feature_local _DISSOLVE_ON
			#pragma shader_feature_local _PATCHES_ON
            #pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#define AVATAR
			#pragma target 5.0
			#include "TakenDefines.cginc"

            v2f vert (appdata v) {
                v2f o = (v2f)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.localPos = v.vertex;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeGrabScreenPos(o.pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvDis = TRANSFORM_TEX(v.uv, _DissolveTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent.xyz = UnityObjectToWorldDir(v.tangent.xyz);
				o.tangent.w = v.tangent.w;
				UNITY_TRANSFER_SHADOW(o, v.uv1);
				UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
				
				float4 texCol = tex2D(_MainTex, i.uv);
				ApplyTransparency(i, texCol.a);

				float3 col = GetBaseColor(i, texCol.rgb);
				float3 aoEmiss = 0;
				float glowPos = 0;

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				FadeShadows(i, atten);
				lighting l = GetLighting(i);
				#if LIGHTING_ENABLED
					GetMetallicWorkflow(i, col);
					col *= l.lightCol;
					#if REFLECTIONS_ENABLED
						ApplyReflections(i, l, col);
					#endif
				#endif
				#if GRADIENT_ENABLED
					ApplyGradient(i, col, glowPos);
				#endif
				ApplyAOEmiss(i, l, col, aoEmiss, glowPos);
				#if RIM_ENABLED
					ApplyRim(i, l, col, glowPos);
				#endif
				#if PATCHES_ENABLED
					ApplySimplexPatches(i, col, glowPos);
				#endif
				#if DISSOLVE_ENABLED
					ApplyDissolve(i, col);
				#endif

				col = Desaturate(col) * _Color.rgb;
				float4 diffuse = float4(col, texCol.a);
				UNITY_APPLY_FOG(i.fogCoord, diffuse);
				return diffuse;
            }
            ENDCG
        }

		Pass {
			Tags {"LightMode"="Always"}
			Cull [_OutlineCulling]
			AlphaToMask [_ATM]
			Stencil {
                Ref [_StencilRef]
                Comp [_OutlineStencilCompare]
                Pass [_OutlineStencilPass]
                Fail [_StencilFail]
                ZFail [_StencilZFail]
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHADITHER_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local _OUTLINE_INVERT_ON
			#pragma shader_feature_local _DISSOLVE_ON
			#pragma shader_feature_local _GRADIENT_ON
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#define AVATAR
			#define OUTLINE
			#pragma target 5.0
			#include "TakenDefines.cginc"

            v2f vert (appdata v) {
                v2f o = (v2f)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				v.vertex.xyz += 0.05*v.normal.xyz*_Thickness * tex2Dlod(_OutlineMask, float4(v.uv.xy,0,0));
				o.localPos = v.vertex;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvDis = TRANSFORM_TEX(v.uv, _DissolveTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.screenPos = ComputeGrabScreenPos(o.pos);
				UNITY_TRANSFER_SHADOW(o, v.uv1);
				UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            float4 frag (v2f i) : SV_Target {

				#if FADE_ENABLED || TRANSPARENT_ENABLED
					discard;
				#endif

				float4 diffuse = 0;
				#if OUTLINE_INVERT_ENABLED
					float4 texCol = tex2D(_MainTex, i.uv);
					float3 col = GetBaseColor(i, texCol.rgb);
					lighting l = (lighting)0;
					float3 aoEmiss = 0;
					float glowPos = 0;
					float atten = 0;
					
					#if GRADIENT_ENABLED
						ApplyGradient(i, col, glowPos);
					#endif
					ApplyAOEmiss(i, l, col, aoEmiss, glowPos);

					col = (1-Desaturate(col)) * _Color.rgb;
					col = lerp(0.5, col, 0.5);
					diffuse = float4(col, texCol.a);
					ApplyTransparency(i, texCol.a);
				#else
					float alpha = tex2D(_MainTex, i.uv).a;
					diffuse = float4(_Color.rgb, alpha*_Color.a);
					ApplyTransparency(i, alpha);
				#endif
				UNITY_APPLY_FOG(i.fogCoord, diffuse);

				return diffuse;
            }
            ENDCG
        }
		 Pass {
            Name "ShadowCaster"
            Tags {"RenderType"="Transparent" "Queue"="Transparent" "LightMode"="ShadowCaster"}
			AlphaToMask Off
			ZWrite On
			Stencil {
                Ref [_StencilRef]
                Comp [_StencilCompare]
                Pass [_StencilPass]
                Fail [_StencilFail]
                ZFail [_StencilZFail]
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHADITHER_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local _DISSOLVE_ON
            #pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma target 5.0
			#define AVATAR
            #include "TakenDefines.cginc"

			v2f vert (appdata v) {
				v2f o = (v2f)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeGrabScreenPos(o.pos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvDis = TRANSFORM_TEX(v.uv, _DissolveTex);
				TRANSFER_SHADOW_CASTER(o);
				return o;
			}

			float4 frag(v2f i) : SV_Target {
				float4 mainTex = tex2D(_MainTex, i.uv);
				ApplyTransparency(i, mainTex.a);
				SHADOW_CASTER_FRAGMENT(i);
			}
            ENDCG
        }
    }
	CustomEditor "TakenEditor"
}