// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "EdShaders/CubeLightDirectionalAmbient"
{
	Properties
	{
		_BrightnessMultiplier("Brightness Multiplier", Float) = 1
		_AboveColour("Above Colour", Color) = (1,1,1,0)
		_MiddleColour("Middle Colour", Color) = (1,1,1,0)
		_BelowColour("Below Colour", Color) = (1,1,1,0)
		_AboveLightWrap("Above Light Wrap", Range( 0 , 1)) = 0
		_MiddleLightWrap("Middle Light Wrap", Range( 0 , 1)) = 0
		_BelowLightWrap("Below Light Wrap", Range( 0 , 1)) = 0
		_ObjectWorldBlend("Object-World Blend", Range( 0 , 1)) = 0
		[Toggle]_OverrideAmbient("Override Ambient", Float) = 0

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

			uniform float _OverrideAmbient;
			uniform float _AboveLightWrap;
			UNITY_DECLARE_TEX2D_NOSAMPLER(_CameraDepthNormalsTexture);
			SamplerState sampler_CameraDepthNormalsTexture;
			uniform float _ObjectWorldBlend;
			uniform float _MiddleLightWrap;
			uniform float _BelowLightWrap;
			uniform float4 _AboveColour;
			uniform float4 _MiddleColour;
			uniform float4 _BelowColour;
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
				float temp_output_548_0 = ( _AboveLightWrap * 0.5 );
				float4 screenPos = i.ase_texcoord1;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float depthDecodedVal48 = 0;
				float3 normalDecodedVal48 = float3(0,0,0);
				DecodeDepthNormal( SAMPLE_TEXTURE2D( _CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, ase_screenPosNorm.xy ), depthDecodedVal48, normalDecodedVal48 );
				float3 viewToObjDir504 = normalize( mul( UNITY_MATRIX_T_MV, float4( normalDecodedVal48, 0 ) ).xyz );
				float3 viewToWorldDir565 = normalize( mul( UNITY_MATRIX_I_V, float4( normalDecodedVal48, 0 ) ).xyz );
				float lerpResult566 = lerp( viewToObjDir504.y , viewToWorldDir565.y , _ObjectWorldBlend);
				float temp_output_552_0 = ( _MiddleLightWrap * 0.5 );
				float temp_output_558_0 = ( _BelowLightWrap * 0.5 );
				float3 appendResult529 = (float3(max( ( temp_output_548_0 + ( ( 1.0 - temp_output_548_0 ) * lerpResult566 ) ) , 0.0 ) , max( ( temp_output_552_0 + ( ( 1.0 - temp_output_552_0 ) * ( 1.0 - abs( lerpResult566 ) ) ) ) , 0.0 ) , max( ( temp_output_558_0 + ( ( 1.0 - temp_output_558_0 ) * -lerpResult566 ) ) , 0.0 )));
				float3 weightedBlendVar572 = appendResult529;
				float4 weightedBlend572 = ( weightedBlendVar572.x*unity_AmbientSky + weightedBlendVar572.y*unity_AmbientEquator + weightedBlendVar572.z*unity_AmbientGround );
				float3 weightedBlendVar518 = appendResult529;
				float4 weightedBlend518 = ( weightedBlendVar518.x*_AboveColour + weightedBlendVar518.y*_MiddleColour + weightedBlendVar518.z*_BelowColour );
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
				
				
				finalColor = ( (( _OverrideAmbient )?( weightedBlend518 ):( weightedBlend572 )) * _BrightnessMultiplier * ( 1.0 - saturate( length( max( ( abs( ( worldToObj141 * 4 ) ) - temp_cast_4 ) , float3( 0,0,0 ) ) ) ) ) );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18600
-1920;338;1906;768;1183.721;1134.273;2.48487;True;False
Node;AmplifyShaderEditor.CommentaryNode;114;-1928.238,-427.0506;Inherit;False;1218.713;324.3466;;4;47;48;50;504;World Normals;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;50;-1878.238,-320.0135;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;47;-1660.282,-340.3415;Inherit;True;Global;_CameraDepthNormalsTexture;_CameraDepthNormalsTexture;7;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DecodeDepthNormalNode;48;-1270.263,-287.5901;Inherit;False;1;0;FLOAT4;0,0,0,0;False;2;FLOAT;0;FLOAT3;1
Node;AmplifyShaderEditor.TransformDirectionNode;504;-992.9884,-349.7941;Inherit;False;View;Object;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;565;-1053.161,-56.50764;Inherit;False;View;World;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;568;-1025.836,146.6231;Inherit;False;Property;_ObjectWorldBlend;Object-World Blend;8;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;157;-347.867,734.6752;Inherit;False;1831.165;426.1548;;10;453;460;452;447;455;454;481;500;141;55;Rounded Cube;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;566;-812.4667,-32.4383;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;534;-363.9404,-508.0499;Inherit;False;1083.413;300.3036;;5;554;524;523;556;551;Middle;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;535;-370.8313,-119.1612;Inherit;False;1110.513;365.8688;;2;527;557;Below;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;533;-362.7273,-1038.392;Inherit;False;920.5643;389.0612;;6;547;544;546;545;548;537;Above;1,1,1,1;0;0
Node;AmplifyShaderEditor.RelayNode;567;-639.5662,-291.3623;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;557;-291.5805,-23.23704;Inherit;False;Property;_BelowLightWrap;Below Light Wrap;6;0;Create;True;0;0;False;0;False;0;0.423;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;537;-338.3274,-988.9764;Inherit;False;Property;_AboveLightWrap;Above Light Wrap;4;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;551;-332.7681,-461.6287;Inherit;False;Property;_MiddleLightWrap;Middle Light Wrap;5;0;Create;True;0;0;False;0;False;0;0.601;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;55;-309.475,775.5215;Inherit;False;Reconstruct World Position From Depth;-1;;22;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.ScaleNode;548;-63.64333,-982.9456;Inherit;False;0.5;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;558;11.03789,-18.95216;Inherit;False;0.5;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;523;-320.1781,-349.6452;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;552;-30.14947,-457.3438;Inherit;False;0.5;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;141;143.1123,793.9868;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;524;-195.1521,-341.8908;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;500;393.6497,825.6288;Inherit;False;4;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;559;171.2698,34.65057;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;527;-334.7986,83.3307;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;545;2.310196,-878.712;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;553;130.0824,-403.7411;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;560;313.9007,105.0628;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;554;272.7132,-333.3289;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;546;164.1461,-822.2669;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;454;573.8916,823.3104;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;481;575.7604,923.6578;Inherit;False;Constant;_1;1;8;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;561;420.1463,-21.94685;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;555;378.9588,-460.3385;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;544;268.6458,-982.4483;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;455;722.2136,808.7365;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;563;858.7204,-785.0576;Inherit;False;719.8577;1210.064;;9;572;518;569;571;570;532;529;531;530;Directional Colour;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;447;863.5811,809.1598;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;556;541.5079,-442.8879;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;562;582.6953,-4.496251;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;547;415.4816,-977.2193;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;531;906.2355,40.85167;Float;False;Property;_MiddleColour;Middle Colour;2;0;Create;True;0;0;False;0;False;1,1,1,0;0.509434,0,0.006212604,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;532;916.942,245.3093;Float;False;Property;_BelowColour;Below Colour;3;0;Create;True;0;0;False;0;False;1,1,1,0;1,0.9295631,0.01415092,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;570;999.1301,-572.2439;Inherit;False;unity_AmbientEquator;0;1;COLOR;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;571;993.9343,-476.1048;Inherit;False;unity_AmbientGround;0;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;529;966.4658,-312.6297;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;530;901.4789,-141.6007;Float;False;Property;_AboveColour;Above Colour;1;0;Create;True;0;0;False;0;False;1,1,1,0;0.1415094,0.004672484,0.00861117,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LengthOpNode;452;1004.725,810.1371;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;569;956.662,-662.4855;Inherit;False;unity_AmbientSky;0;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;460;1146.637,807.7771;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SummedBlendNode;518;1346.73,2.86211;Inherit;False;5;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SummedBlendNode;572;1366.681,-545.0694;Inherit;False;5;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;8;1843.273,222.6335;Float;False;Property;_BrightnessMultiplier;Brightness Multiplier;0;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;453;1313.882,810.1104;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;573;1740.248,-296.7592;Inherit;False;Property;_OverrideAmbient;Override Ambient;9;0;Create;True;0;0;False;0;False;0;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;2232.032,127.9029;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;183;2481.401,128.138;Float;False;True;-1;2;ASEMaterialInspector;100;1;EdShaders/CubeLightDirectionalAmbient;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;4;1;False;-1;1;False;-1;0;2;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;1;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;4;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;True;0
WireConnection;47;1;50;0
WireConnection;48;0;47;0
WireConnection;504;0;48;1
WireConnection;565;0;48;1
WireConnection;566;0;504;2
WireConnection;566;1;565;2
WireConnection;566;2;568;0
WireConnection;567;0;566;0
WireConnection;548;0;537;0
WireConnection;558;0;557;0
WireConnection;523;0;567;0
WireConnection;552;0;551;0
WireConnection;141;0;55;0
WireConnection;524;0;523;0
WireConnection;500;0;141;0
WireConnection;559;0;558;0
WireConnection;527;0;567;0
WireConnection;545;0;548;0
WireConnection;553;0;552;0
WireConnection;560;0;559;0
WireConnection;560;1;527;0
WireConnection;554;0;553;0
WireConnection;554;1;524;0
WireConnection;546;0;545;0
WireConnection;546;1;567;0
WireConnection;454;0;500;0
WireConnection;561;0;558;0
WireConnection;561;1;560;0
WireConnection;555;0;552;0
WireConnection;555;1;554;0
WireConnection;544;0;548;0
WireConnection;544;1;546;0
WireConnection;455;0;454;0
WireConnection;455;1;481;0
WireConnection;447;0;455;0
WireConnection;556;0;555;0
WireConnection;562;0;561;0
WireConnection;547;0;544;0
WireConnection;529;0;547;0
WireConnection;529;1;556;0
WireConnection;529;2;562;0
WireConnection;452;0;447;0
WireConnection;460;0;452;0
WireConnection;518;0;529;0
WireConnection;518;1;530;0
WireConnection;518;2;531;0
WireConnection;518;3;532;0
WireConnection;572;0;529;0
WireConnection;572;1;569;0
WireConnection;572;2;570;0
WireConnection;572;3;571;0
WireConnection;453;0;460;0
WireConnection;573;0;572;0
WireConnection;573;1;518;0
WireConnection;144;0;573;0
WireConnection;144;1;8;0
WireConnection;144;2;453;0
WireConnection;183;0;144;0
ASEEND*/
//CHKSM=05BCA32CB9DF498AFC02568D9848DC598673106E