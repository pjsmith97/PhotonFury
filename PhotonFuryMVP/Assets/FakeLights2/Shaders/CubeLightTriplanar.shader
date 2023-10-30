// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "EdShaders/CubeLightTriplanar"
{
	Properties
	{
		_BrightnessMultiplier("Brightness Multiplier", Float) = 1
		_Tiling("Tiling", Float) = 1
		_MainTex("MainTex", 2D) = "white" {}
		_Color("Color", Color) = (0,0,0,0)

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One
		AlphaToMask Off
		Cull Front
		ColorMask RGBA
		ZWrite Off
		ZTest GEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
			#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
			#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex.SampleLevel(samplerTex,coord, lod)
			#define SAMPLE_TEXTURE2D_BIAS(tex,samplerTex,coord,bias) tex.SampleBias(samplerTex,coord,bias)
			#define SAMPLE_TEXTURE2D_GRAD(tex,samplerTex,coord,ddx,ddy) tex.SampleGrad(samplerTex,coord,ddx,ddy)
			#else//ASE Sampling Macros
			#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
			#define SAMPLE_TEXTURE2D_LOD(tex,samplerTex,coord,lod) tex2Dlod(tex,float4(coord,0,lod))
			#define SAMPLE_TEXTURE2D_BIAS(tex,samplerTex,coord,bias) tex2Dbias(tex,float4(coord,0,bias))
			#define SAMPLE_TEXTURE2D_GRAD(tex,samplerTex,coord,ddx,ddy) tex2Dgrad(tex,coord,ddx,ddy)
			#endif//ASE Sampling Macros
			


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			UNITY_DECLARE_TEX2D_NOSAMPLER(_CameraDepthNormalsTexture);
			SamplerState sampler_CameraDepthNormalsTexture;
			UNITY_DECLARE_TEX2D_NOSAMPLER(_MainTex);
			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
			uniform float4 _CameraDepthTexture_TexelSize;
			uniform float _Tiling;
			SamplerState sampler_MainTex;
			uniform float _BrightnessMultiplier;
			uniform float4 _Color;
			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			float3 InvertDepthDir72_g22( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301
				result *= float3(1,1,-1);
				#endif
				return result;
			}
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float4 screenPos = i.ase_texcoord1;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float depthDecodedVal48 = 0;
				float3 normalDecodedVal48 = float3(0,0,0);
				DecodeDepthNormal( SAMPLE_TEXTURE2D( _CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, ase_screenPosNorm.xy ), depthDecodedVal48, normalDecodedVal48 );
				float3 viewToWorldDir565 = normalize( mul( UNITY_MATRIX_I_V, float4( normalDecodedVal48, 0 ) ).xyz );
				float3 temp_output_610_0 = abs( viewToWorldDir565 );
				float2 UV22_g23 = ase_screenPosNorm.xy;
				float2 localUnStereo22_g23 = UnStereo( UV22_g23 );
				float2 break64_g22 = localUnStereo22_g23;
				float clampDepth69_g22 = SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g22 = ( 1.0 - clampDepth69_g22 );
				#else
				float staticSwitch38_g22 = clampDepth69_g22;
				#endif
				float3 appendResult39_g22 = (float3(break64_g22.x , break64_g22.y , staticSwitch38_g22));
				float4 appendResult42_g22 = (float4((appendResult39_g22*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g22 = mul( unity_CameraInvProjection, appendResult42_g22 );
				float3 In72_g22 = ( (temp_output_43_0_g22).xyz / (temp_output_43_0_g22).w );
				float3 localInvertDepthDir72_g22 = InvertDepthDir72_g22( In72_g22 );
				float4 appendResult49_g22 = (float4(localInvertDepthDir72_g22 , 1.0));
				float4 temp_output_55_0 = mul( unity_CameraToWorld, appendResult49_g22 );
				float3 break608 = ( (temp_output_55_0).xyz * _Tiling );
				float2 appendResult603 = (float2(break608.y , break608.z));
				float2 appendResult604 = (float2(break608.z , break608.x));
				float2 appendResult605 = (float2(break608.x , break608.y));
				float3 weightedBlendVar609 = ( temp_output_610_0 * temp_output_610_0 );
				float4 weightedBlend609 = ( weightedBlendVar609.x*SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, appendResult603 ) + weightedBlendVar609.y*SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, appendResult604 ) + weightedBlendVar609.z*SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, appendResult605 ) );
				float3 worldToObj141 = mul( unity_WorldToObject, float4( temp_output_55_0.xyz, 1 ) ).xyz;
				float3 temp_cast_4 = (1.0).xxx;
				
				
				finalColor = ( weightedBlend609 * _BrightnessMultiplier * ( 1.0 - saturate( length( max( ( abs( ( worldToObj141 * 4 ) ) - temp_cast_4 ) , float3( 0,0,0 ) ) ) ) ) * _Color );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18600
-1920;338;1906;768;2422.313;1435.892;3.316634;True;False
Node;AmplifyShaderEditor.CommentaryNode;157;354.3948,701.2342;Inherit;False;1831.165;426.1548;;9;453;460;452;447;455;454;481;500;141;Rounded Cube;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;55;-933.136,786.2288;Inherit;False;Reconstruct World Position From Depth;-1;;22;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;114;-1908.355,-499.1274;Inherit;False;1218.713;324.3466;;4;47;48;50;565;World Normals;1,1,1,1;0;0
Node;AmplifyShaderEditor.TransformPositionNode;141;845.3744,760.5458;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;613;-534.0414,-417.5161;Inherit;False;1994.835;986.8263;;14;605;604;599;603;602;600;601;609;608;571;612;610;611;614;Triplanar Texture;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;50;-1858.355,-392.0903;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleNode;500;1095.912,792.1878;Inherit;False;4;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;571;-438.0403,-22.29449;Inherit;False;Property;_Tiling;Tiling;2;0;Create;True;0;0;False;0;False;1;0.73;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;481;1278.022,890.2168;Inherit;False;Constant;_1;1;8;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;614;-463.6035,-144.8987;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;47;-1640.399,-412.4183;Inherit;True;Global;_CameraDepthNormalsTexture;_CameraDepthNormalsTexture;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.AbsOpNode;454;1276.154,789.8694;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;455;1424.476,775.2955;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;612;-236.9859,-104.6705;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DecodeDepthNormalNode;48;-1250.38,-359.6669;Inherit;False;1;0;FLOAT4;0,0,0,0;False;2;FLOAT;0;FLOAT3;1
Node;AmplifyShaderEditor.BreakToComponentsNode;608;-14.308,-104.5856;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMaxOpNode;447;1565.843,775.7188;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;565;-962.7234,-383.3818;Inherit;False;View;World;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LengthOpNode;452;1706.987,776.6961;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;604;267.7076,-72.54501;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;603;262.47,-178.2656;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.AbsOpNode;610;914.3183,-367.5162;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;605;266.774,39.49334;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;599;154.2128,295.9625;Inherit;True;Property;_MainTex;MainTex;3;0;Create;True;0;0;False;0;False;None;56c3e2f10ff9c65448f9b1b19afdf679;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;602;577.3643,230.6256;Inherit;True;Property;_TextureSample2;Texture Sample 2;15;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;611;1063.703,-346.1968;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;460;1848.899,774.3361;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;600;555.6499,-236.0209;Inherit;True;Property;_TextureSample0;Texture Sample 0;13;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;601;578.8007,18.21868;Inherit;True;Property;_TextureSample1;Texture Sample 1;14;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;453;2016.144,776.6694;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;615;1972.228,-162.3048;Inherit;False;Property;_Color;Color;4;0;Create;True;0;0;False;0;False;0,0,0,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SummedBlendNode;609;1253.794,-202.4165;Inherit;False;5;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;8;1843.273,222.6335;Float;False;Property;_BrightnessMultiplier;Brightness Multiplier;0;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;2232.032,127.9029;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;183;2481.401,125.4933;Float;False;True;-1;2;ASEMaterialInspector;100;1;EdShaders/CubeLightTriplanar;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;4;1;False;-1;1;False;-1;0;2;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;1;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;4;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;True;0
WireConnection;141;0;55;0
WireConnection;500;0;141;0
WireConnection;614;0;55;0
WireConnection;47;1;50;0
WireConnection;454;0;500;0
WireConnection;455;0;454;0
WireConnection;455;1;481;0
WireConnection;612;0;614;0
WireConnection;612;1;571;0
WireConnection;48;0;47;0
WireConnection;608;0;612;0
WireConnection;447;0;455;0
WireConnection;565;0;48;1
WireConnection;452;0;447;0
WireConnection;604;0;608;2
WireConnection;604;1;608;0
WireConnection;603;0;608;1
WireConnection;603;1;608;2
WireConnection;610;0;565;0
WireConnection;605;0;608;0
WireConnection;605;1;608;1
WireConnection;602;0;599;0
WireConnection;602;1;605;0
WireConnection;611;0;610;0
WireConnection;611;1;610;0
WireConnection;460;0;452;0
WireConnection;600;0;599;0
WireConnection;600;1;603;0
WireConnection;601;0;599;0
WireConnection;601;1;604;0
WireConnection;453;0;460;0
WireConnection;609;0;611;0
WireConnection;609;1;600;0
WireConnection;609;2;601;0
WireConnection;609;3;602;0
WireConnection;144;0;609;0
WireConnection;144;1;8;0
WireConnection;144;2;453;0
WireConnection;144;3;615;0
WireConnection;183;0;144;0
ASEEND*/
//CHKSM=3BB51EDDE2EA9F730864C54B8F419509C4B0ECB8