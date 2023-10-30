// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "EdShaders/CubeLightFresnelRim"
{
	Properties
	{
		_BrightnessMultiplier("Brightness Multiplier", Float) = 1
		_RimColour("Rim Colour", Color) = (1,1,1,0)
		_CentreColour("Centre Colour", Color) = (1,1,1,0)
		_RimBias("Rim Bias", Float) = 0
		_RimScale("Rim Scale", Float) = 1
		_RimPower("Rim Power", Float) = 5

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
			#define ASE_NEEDS_FRAG_WORLD_POSITION
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
			uniform float _RimBias;
			uniform float _RimScale;
			uniform float _RimPower;
			uniform float4 _CentreColour;
			uniform float4 _RimColour;
			uniform float _BrightnessMultiplier;
			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
			uniform float4 _CameraDepthTexture_TexelSize;
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
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(WorldPosition);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float4 screenPos = i.ase_texcoord1;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float depthDecodedVal48 = 0;
				float3 normalDecodedVal48 = float3(0,0,0);
				DecodeDepthNormal( SAMPLE_TEXTURE2D( _CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, ase_screenPosNorm.xy ), depthDecodedVal48, normalDecodedVal48 );
				float3 viewToWorldDir565 = normalize( mul( UNITY_MATRIX_I_V, float4( normalDecodedVal48, 0 ) ).xyz );
				float fresnelNdotV570 = dot( viewToWorldDir565, ase_worldViewDir );
				float fresnelNode570 = ( _RimBias + _RimScale * pow( 1.0 - fresnelNdotV570, _RimPower ) );
				float temp_output_584_0 = saturate( fresnelNode570 );
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
				float3 worldToObj141 = mul( unity_WorldToObject, float4( mul( unity_CameraToWorld, appendResult49_g22 ).xyz, 1 ) ).xyz;
				float3 temp_cast_4 = (1.0).xxx;
				
				
				finalColor = ( ( ( ( 1.0 - temp_output_584_0 ) * _CentreColour ) + ( temp_output_584_0 * _RimColour ) ) * _BrightnessMultiplier * ( 1.0 - saturate( length( max( ( abs( ( worldToObj141 * 4 ) ) - temp_cast_4 ) , float3( 0,0,0 ) ) ) ) ) );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18600
251;868;1906;780;2281.13;885.6844;2.180666;True;False
Node;AmplifyShaderEditor.CommentaryNode;157;-761.335,297.4837;Inherit;False;1831.165;426.1548;;10;453;460;452;447;455;454;481;500;141;55;Rounded Cube;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;114;-1928.238,-427.0506;Inherit;False;1218.713;324.3466;;4;47;48;50;565;World Normals;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;55;-722.9431,338.33;Inherit;False;Reconstruct World Position From Depth;-1;;22;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;50;-1878.238,-320.0135;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode;141;-270.3556,356.7954;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;47;-1660.282,-340.3415;Inherit;True;Global;_CameraDepthNormalsTexture;_CameraDepthNormalsTexture;3;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleNode;500;-19.81821,388.4373;Inherit;False;4;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;583;-460.0995,-636.7335;Inherit;False;1409.767;717.0557;;11;579;577;580;581;582;576;572;575;574;570;584;Fresnel Colour;1,1,1,1;0;0
Node;AmplifyShaderEditor.DecodeDepthNormalNode;48;-1270.263,-287.5901;Inherit;False;1;0;FLOAT4;0,0,0,0;False;2;FLOAT;0;FLOAT3;1
Node;AmplifyShaderEditor.RangedFloatNode;575;-406.5029,-259.4991;Inherit;False;Property;_RimPower;Rim Power;6;0;Create;True;0;0;False;0;False;5;3.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;574;-410.0995,-424.0805;Inherit;False;Property;_RimScale;Rim Scale;5;0;Create;True;0;0;False;0;False;1;50.83;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;565;-972.7595,-341.173;Inherit;False;View;World;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;572;-393.8412,-536.5339;Inherit;False;Property;_RimBias;Rim Bias;4;0;Create;True;0;0;False;0;False;0;-0.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;481;162.2925,486.4663;Inherit;False;Constant;_1;1;8;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;454;160.4237,386.119;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;455;308.7457,371.545;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FresnelNode;570;-185.5362,-382.9472;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;584;106.6995,-368.8665;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;447;450.1132,371.9684;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;576;135.0434,-131.6778;Float;False;Property;_RimColour;Rim Colour;1;0;Create;True;0;0;False;0;False;1,1,1,0;0.4528302,0.1046636,0.1046636,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LengthOpNode;452;591.2571,372.9456;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;577;300.4229,-586.7335;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;579;364.1046,-450.003;Float;False;Property;_CentreColour;Centre Colour;2;0;Create;True;0;0;False;0;False;1,1,1,0;0.8490566,0.4605732,0.6471331,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;581;350.3921,-216.1002;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;460;733.1691,370.5857;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;580;642.4531,-548.9134;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;582;797.6678,-222.104;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;453;900.414,372.9189;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;1467.085,-62.0493;Float;False;Property;_BrightnessMultiplier;Brightness Multiplier;0;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;1855.844,-156.78;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;183;2105.214,-156.5448;Float;False;True;-1;2;ASEMaterialInspector;100;1;EdShaders/CubeLightFresnelRim;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;4;1;False;-1;1;False;-1;0;2;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;1;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;4;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;True;0
WireConnection;141;0;55;0
WireConnection;47;1;50;0
WireConnection;500;0;141;0
WireConnection;48;0;47;0
WireConnection;565;0;48;1
WireConnection;454;0;500;0
WireConnection;455;0;454;0
WireConnection;455;1;481;0
WireConnection;570;0;565;0
WireConnection;570;1;572;0
WireConnection;570;2;574;0
WireConnection;570;3;575;0
WireConnection;584;0;570;0
WireConnection;447;0;455;0
WireConnection;452;0;447;0
WireConnection;577;0;584;0
WireConnection;581;0;584;0
WireConnection;581;1;576;0
WireConnection;460;0;452;0
WireConnection;580;0;577;0
WireConnection;580;1;579;0
WireConnection;582;0;580;0
WireConnection;582;1;581;0
WireConnection;453;0;460;0
WireConnection;144;0;582;0
WireConnection;144;1;8;0
WireConnection;144;2;453;0
WireConnection;183;0;144;0
ASEEND*/
//CHKSM=741DAAD2657437AC0C47EFD7D5EB89674D86EA89