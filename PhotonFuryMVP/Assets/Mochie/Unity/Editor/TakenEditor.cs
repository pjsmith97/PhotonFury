using System;
using System.IO;
using System.Reflection;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using Mochie;

public class TakenEditor : ShaderGUI {

    public static Dictionary<Material, Toggles> foldouts = new Dictionary<Material, Toggles>();
	Dictionary<Action, GUIContent> baseTabButtons = new Dictionary<Action, GUIContent>();
	Dictionary<Action, GUIContent> lightingTabButtons = new Dictionary<Action, GUIContent>();
	Dictionary<Action, GUIContent> gradientTabButtons = new Dictionary<Action, GUIContent>();
	Dictionary<Action, GUIContent> noiseTabButtons = new Dictionary<Action, GUIContent>();
	Dictionary<Action, GUIContent> outlineTabButtons = new Dictionary<Action, GUIContent>();
	Dictionary<Action, GUIContent> rimTabButtons = new Dictionary<Action, GUIContent>();
	Dictionary<Action, GUIContent> dissolveTabButtons = new Dictionary<Action, GUIContent>();
	Dictionary<Action, GUIContent> emissTabButtons = new Dictionary<Action, GUIContent>();
    Toggles toggles = new Toggles(new string[] {
			"BASE",
			"LIGHTING",
			"RIM",
			"EMISSION",
			"GRADIENT",
			"NOISE PATCHES",
			"DISSOLVE",
			"OUTLINE",
	}, 0);

	string header = "TakenHeader_Pro";
	string versionLabel = "v1.1";

	GUIContent maskLabel = new GUIContent("Mask");
    GUIContent albedoLabel = new GUIContent("Albedo");
	GUIContent mirrorTexLabel = new GUIContent("Albedo (Mirror)");
    GUIContent emissTexLabel = new GUIContent("Emission Map");
    GUIContent normalTexLabel = new GUIContent("Normal");
    GUIContent metallicTexLabel = new GUIContent("Metallic");
    GUIContent roughnessTexLabel = new GUIContent("Roughness");
    GUIContent occlusionTexLabel = new GUIContent("Occlusion");
    GUIContent heightTexLabel = new GUIContent("Height");
    GUIContent reflCubeLabel = new GUIContent("Cubemap");
    GUIContent shadowRampLabel = new GUIContent("Ramp");
    GUIContent specularTexLabel = new GUIContent("Specular Map");
    GUIContent primaryMapsLabel = new GUIContent("Primary Maps");
    GUIContent detailMapsLabel = new GUIContent("Detail Maps");
	GUIContent dissolveTexLabel = new GUIContent("Dissolve Map");
	GUIContent dissolveRimTexLabel = new GUIContent("Rim Color");
	GUIContent colorLabel = new GUIContent("Color");
	GUIContent packedTexLabel = new GUIContent("Packed Texture");
	GUIContent cubemapLabel = new GUIContent("Cubemap");
	GUIContent translucTexLabel = new GUIContent("Thickness Map");
	GUIContent tintLabel = new GUIContent("Tint");
	GUIContent filteringLabel = new GUIContent("PBR Filtering");
	GUIContent smoothTexLabel = new GUIContent("Smoothness");

	// Avatar Props
	MaterialProperty _BlendMode = null;
	MaterialProperty _ZWrite = null;
	MaterialProperty _Cutoff = null;
	MaterialProperty _Color = null;
	MaterialProperty _Invert = null;
	MaterialProperty _Smoothstep = null;
	MaterialProperty _Culling = null;
	MaterialProperty _MainTex = null;
	MaterialProperty _BumpScale = null;
	MaterialProperty _BumpMap = null;

	MaterialProperty _EnableLighting = null;
	MaterialProperty _EnableSH = null;
	MaterialProperty _EnableReflections = null;
	MaterialProperty _Metallic = null;
	MaterialProperty _Roughness = null;
	MaterialProperty _ReflectionStr = null;
	MaterialProperty _MetallicMap = null;
	MaterialProperty _RoughnessMap = null;
	MaterialProperty _ReflectionMask = null;

	MaterialProperty _EnableRim = null;
	MaterialProperty _RimBrightness = null;
	MaterialProperty _RimWidth = null;
	MaterialProperty _RimEdge = null;
	MaterialProperty _RimGradMask = null;
	MaterialProperty _RimMask = null;

	MaterialProperty _EmissStr = null;
	MaterialProperty _EmissPow = null;
	MaterialProperty _EmissGradMasking = null;
	MaterialProperty _EmissTex = null;
	MaterialProperty _EmissGradMask = null;
	MaterialProperty _EmissInvert = null;

	MaterialProperty _EnableGradient = null;
	MaterialProperty _GradientInvert = null;
	MaterialProperty _GradientAxis = null;
	MaterialProperty _GradientNoiseScale = null;
	MaterialProperty _GradientBrightness = null;
	MaterialProperty _GradientHeightMax = null;
	MaterialProperty _GradientHeightMin = null;
	MaterialProperty _GradientSpeed = null;
	MaterialProperty _GradientContrast = null;
	MaterialProperty _GradientMask = null;

	MaterialProperty _EnablePatches = null;
	MaterialProperty _NoiseScale = null;
	MaterialProperty _NoiseBrightness = null;
	MaterialProperty _NoiseCutoff = null;
	MaterialProperty _NoiseSmooth = null;
	MaterialProperty _NoiseMask = null;

	MaterialProperty _EnableDissolve = null;
	MaterialProperty _DissolveTex = null;
	MaterialProperty _DissolveAmt = null;
	MaterialProperty _DissolveRimBrightness = null;
	MaterialProperty _DissolveRimWidth = null;

	MaterialProperty _EnableOutline = null;
	MaterialProperty _InvertedOutline = null;
	MaterialProperty _Thickness = null;
	MaterialProperty _OutlineMask = null;
	MaterialProperty _StencilOutline = null;


    BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;

	bool m_FirstTimeApply = true;

    MaterialEditor m_me;
    public override void OnGUI(MaterialEditor me, MaterialProperty[] props) {
		Material mat = (Material)me.target;
		mat.DisableKeyword("_");
		if (m_FirstTimeApply) {
			m_FirstTimeApply = false;
		}

		// Find properties
        foreach (var property in GetType().GetFields(bindingFlags)){
            if (property.FieldType == typeof(MaterialProperty)){
                property.SetValue(this, FindProperty(property.Name, props));
            }
        }

		// Check name of shader to determine if certain properties should be displayed
        bool isTransparent = _BlendMode.floatValue >= 3;
        bool isCutout = _BlendMode.floatValue > 0 && _BlendMode.floatValue < 3;

		if (!EditorGUIUtility.isProSkin){
			header = "TakenHeader";
		}

		// Add mat to foldout dictionary if it isn't in there yet
		if (!foldouts.ContainsKey(mat))
			foldouts.Add(mat, toggles);


		foreach (var obj in _BlendMode.targets)
			ApplyMaterialSettings((Material)obj);

		// Return here to reduce editor overhead if it's not visible
		if (!me.isVisible)
			return;

		ClearDictionaries();

        Texture2D headerTex = (Texture2D)Resources.Load(header, typeof(Texture2D));

        GUILayout.Label(headerTex);
		MGUI.Space4();

		baseTabButtons.Add(()=>{Toggles.CollapseFoldouts(mat, foldouts, 1);}, MGUI.collapseLabel);
		baseTabButtons.Add(()=>{ResetBase();}, MGUI.resetLabel);
		Action baseTabAction = ()=>{
			MGUI.PropertyGroup(()=>{
				me.RenderQueueField();
				me.ShaderProperty(_BlendMode, "Blending Mode");
				if (_BlendMode.floatValue == 4)
					me.ShaderProperty(_ZWrite, "ZWrite");
				me.ShaderProperty(_Culling, "Culling");
				me.ShaderProperty(_Color, Tips.globalTint);
				if (_BlendMode.floatValue == 1){
					me.ShaderProperty(_Cutoff, "Cutout");
				}
				me.ShaderProperty(_Smoothstep, "Smoothstep");
			});
			MGUI.PropertyGroup(()=>{
				me.TexturePropertySingleLine(new GUIContent("Base Color"), _MainTex, _Invert);
				MGUI.TexPropLabel("Invert", 95);
				me.TexturePropertySingleLine(Tips.emissionAO, _EmissTex, _EmissInvert);
				MGUI.TexPropLabel("Invert", 95);
				me.TexturePropertySingleLine(Tips.normalMapText, _BumpMap, _BumpScale);
				MGUI.TexPropLabel("Strength", 107);
				MGUI.TextureSO(me, _MainTex);
			});
		};
		Foldouts.Foldout("BASE", foldouts, baseTabButtons, mat, me, baseTabAction);

		lightingTabButtons.Add(()=>{ResetLighting();}, MGUI.resetLabel);
		Action lightingTabAction = ()=>{
			me.ShaderProperty(_EnableLighting, "Enable");
			MGUI.ToggleGroup(_EnableLighting.floatValue == 0);
			MGUI.PropertyGroup(()=>{
				me.ShaderProperty(_EnableSH, Tips.shStr);
				me.ShaderProperty(_EnableReflections, "Reflections");
			});
			MGUI.ToggleGroup(_EnableReflections.floatValue == 0);
			MGUI.PropertyGroup(()=>{
				me.TexturePropertySingleLine(Tips.metallicMapText, _MetallicMap, _Metallic);
				me.TexturePropertySingleLine(Tips.roughnessTexLabel, _RoughnessMap, _Roughness);
				me.TexturePropertySingleLine(new GUIContent("Reflections"), _ReflectionMask, _ReflectionStr);
			});
			MGUI.ToggleGroupEnd();
			MGUI.ToggleGroupEnd();
		};
		Foldouts.Foldout("LIGHTING", foldouts, lightingTabButtons, mat, me, lightingTabAction);

		rimTabButtons.Add(()=>{ResetRim();}, MGUI.resetLabel);
		Action rimTabAction = ()=>{
			me.ShaderProperty(_EnableRim, "Enable");
			MGUI.ToggleGroup(_EnableRim.floatValue == 0);
			MGUI.PropertyGroup(()=>{
				me.ShaderProperty(_RimBrightness, "Strength");
				me.ShaderProperty(_RimWidth, "Width");
				me.ShaderProperty(_RimEdge, "Sharpness");
				me.ShaderProperty(_RimGradMask, Tips.gradientRestriction);		
				me.TexturePropertySingleLine(new GUIContent("Mask"), _RimMask);
			});
			MGUI.ToggleGroupEnd();
		};
		Foldouts.Foldout("RIM", foldouts, rimTabButtons, mat, me, rimTabAction);

		emissTabButtons.Add(()=>{ResetEmission();}, MGUI.resetLabel);
		Action emissTabAction = ()=>{
			MGUI.PropertyGroup(()=>{
				me.ShaderProperty(_EmissStr, "Strength");
				me.ShaderProperty(_EmissPow, "Exponent");
				me.ShaderProperty(_EmissGradMasking, Tips.emissionGradRestrict);
				me.TexturePropertySingleLine(Tips.restrictionMask, _EmissGradMask);
			});
		};
		Foldouts.Foldout("EMISSION", foldouts, emissTabButtons, mat, me, emissTabAction);

		gradientTabButtons.Add(()=>{ResetGradient();}, MGUI.resetLabel);
		Action gradientTabAction = ()=>{
			me.ShaderProperty(_EnableGradient, "Enable");
			MGUI.ToggleGroup(_EnableGradient.floatValue == 0);
			MGUI.PropertyGroup(()=>{
				me.ShaderProperty(_GradientInvert, "Invert Axis");
				me.ShaderProperty(_GradientAxis, Tips.gradientAxis);
			});
			MGUI.PropertyGroup(()=>{
				MGUI.Vector3Field(_GradientNoiseScale, "Noise Scale", false);
				me.ShaderProperty(_GradientBrightness, "Brightness");
				me.ShaderProperty(_GradientHeightMax, Tips.endPos);
				me.ShaderProperty(_GradientHeightMin, Tips.startPos);
				me.ShaderProperty(_GradientSpeed, "Scroll Speed");
				me.ShaderProperty(_GradientContrast, "Contrast");
				me.TexturePropertySingleLine(new GUIContent("Mask"), _GradientMask);
			});
			MGUI.ToggleGroupEnd();
		};
		Foldouts.Foldout("GRADIENT", foldouts, gradientTabButtons, mat, me, gradientTabAction);

		noiseTabButtons.Add(()=>{ResetNoise();}, MGUI.resetLabel);
		Action noiseTabAction = ()=>{
			me.ShaderProperty(_EnablePatches, "Enable");
			MGUI.ToggleGroup(_EnablePatches.floatValue == 0);
			MGUI.PropertyGroup(()=>{
				MGUI.Vector2Field(_NoiseScale, "Scale");
				me.ShaderProperty(_NoiseBrightness, "Brightness");
				me.ShaderProperty(_NoiseCutoff, "Cutoff");
				me.ShaderProperty(_NoiseSmooth, Tips.noiseSmoothing);
				me.TexturePropertySingleLine(new GUIContent("Mask"), _NoiseMask);
			});
			MGUI.ToggleGroupEnd();
		};
		Foldouts.Foldout("NOISE PATCHES", foldouts, noiseTabButtons, mat, me, noiseTabAction);

		dissolveTabButtons.Add(()=>{ResetDissolve();}, MGUI.resetLabel);
		Action dissolveTabAction = ()=>{
			if (isCutout || isTransparent){
				me.ShaderProperty(_EnableDissolve, "Enable");
				MGUI.ToggleGroup(_EnableDissolve.floatValue == 0);
				MGUI.PropertyGroup(()=>{
					me.TexturePropertySingleLine(new GUIContent("Dissolve Map"), _DissolveTex);
					MGUI.TextureSO(me, _DissolveTex, _DissolveTex.textureValue);
					MGUI.Space4();
					me.ShaderProperty(_DissolveAmt, "Strength");
					me.ShaderProperty(_DissolveRimBrightness, "Rim Brightness");
					me.ShaderProperty(_DissolveRimWidth, "Rim Width");
				});
				MGUI.ToggleGroupEnd();
			}
			else {
				MGUI.CenteredText("REQUIRES NON-OPAQUE BLEND MODE", 11, 0,0);
				MGUI.Space2();
			} 
		};
		Foldouts.Foldout("DISSOLVE", foldouts, dissolveTabButtons, mat, me, dissolveTabAction);

		outlineTabButtons.Add(()=>{ResetOutline();}, MGUI.resetLabel);
		Action outlineTabAction = ()=>{
			if (!isTransparent){
				me.ShaderProperty(_EnableOutline, "Enable");
				MGUI.ToggleGroup(_EnableOutline.floatValue == 0);
				MGUI.PropertyGroup(()=>{
					me.ShaderProperty(_InvertedOutline, Tips.invertTint);
					me.ShaderProperty(_StencilOutline, Tips.stencilMode);
				});
				MGUI.PropertyGroup(()=>{
					me.ShaderProperty(_Thickness, "Thickness");
					me.TexturePropertySingleLine(new GUIContent("Mask"), _OutlineMask);
				});
				MGUI.ToggleGroupEnd();
			}
			else MGUI.CenteredText("REQUIRES NON-TRANSPARENT BLEND MODE", 10, 0, 0);
		};
		Foldouts.Foldout("OUTLINE", foldouts, outlineTabButtons, mat, me, outlineTabAction);

		MGUI.DoFooter(versionLabel);
    }

	void ApplyMaterialSettings(Material mat){
		int blendMode = mat.GetInt("_BlendMode");
		int outlineToggle = mat.GetInt("_EnableOutline");
		int lightingToggle = mat.GetInt("_EnableLighting");
		int reflectionsToggle = mat.GetInt("_EnableReflections");
		int rimToggle = mat.GetInt("_EnableRim");
		int gradientToggle = mat.GetInt("_EnableGradient");
		int dissolveToggle = mat.GetInt("_EnableDissolve");
		int patchesToggle = mat.GetInt("_EnablePatches");
		int invertToggle = mat.GetInt("_InvertedOutline");
		int stencilToggle = mat.GetInt("_StencilOutline");

		mat.SetInt("_ATM", blendMode == 1 ? 1 : 0);
		mat.SetShaderPassEnabled("Always", outlineToggle  == 1);

		// Sync the outline stencil settings with base pass stencil settings when not using stencil mode
		if (outlineToggle == 0 || stencilToggle == 0){
			ApplyOutlineNormalConfig(mat);
		}
		if (outlineToggle == 1 && stencilToggle == 1){
			ApplyOutlineStencilConfig(mat);
		}

		SetKeyword(mat, "_ALPHATEST_ON", blendMode == 1);
		SetKeyword(mat, "_ALPHADITHER_ON", blendMode == 2);
		SetKeyword(mat, "_ALPHABLEND_ON", blendMode == 3);
		SetKeyword(mat, "_ALPHAPREMULTIPLY_ON", blendMode == 4);
		SetKeyword(mat, "_LIGHTING_ON", lightingToggle == 1);
		SetKeyword(mat, "_REFLECTIONS_ON", lightingToggle == 1 && reflectionsToggle == 1);
		SetKeyword(mat, "_RIM_ON", rimToggle == 1);
		SetKeyword(mat, "_GRADIENT_ON", gradientToggle == 1);
		SetKeyword(mat, "_DISSOLVE_ON", dissolveToggle == 1);
		SetKeyword(mat, "_PATCHES_ON", patchesToggle == 1);
		SetKeyword(mat, "_OUTLINE_INVERT_ON", outlineToggle == 1 && invertToggle == 1);
	}

	void ApplyOutlineNormalConfig(Material mat){
		mat.SetFloat("_OutlineStencilRef", mat.GetFloat("_StencilRef"));
		mat.SetFloat("_OutlineStencilPass", mat.GetFloat("_StencilPass"));
		mat.SetFloat("_OutlineStencilFail", mat.GetFloat("_StencilFail"));
		mat.SetFloat("_OutlineStencilZFail", mat.GetFloat("_StencilZFail"));
		mat.SetFloat("_OutlineStencilCompare", mat.GetFloat("_StencilCompare"));
		mat.SetInt("_OutlineCulling", 1);
	}

	void ApplyOutlineStencilConfig(Material mat){
		mat.SetFloat("_StencilPass", (float)UnityEngine.Rendering.StencilOp.Replace);
		mat.SetFloat("_StencilFail", (float)UnityEngine.Rendering.StencilOp.Keep);
		mat.SetFloat("_StencilZFail", (float)UnityEngine.Rendering.StencilOp.Keep);
		mat.SetFloat("_StencilCompare", (float)UnityEngine.Rendering.CompareFunction.Always);

		mat.SetFloat("_OutlineStencilPass", (float)UnityEngine.Rendering.StencilOp.Keep);
		mat.SetFloat("_OutlineStencilFail", (float)UnityEngine.Rendering.StencilOp.Keep);
		mat.SetFloat("_OutlineStencilZFail", (float)UnityEngine.Rendering.StencilOp.Keep);
		mat.SetFloat("_OutlineStencilCompare", (float)UnityEngine.Rendering.CompareFunction.NotEqual);
		mat.SetInt("_OutlineCulling", 0);
	}

	void SetKeyword(Material m, string keyword, bool state) {
		if (state)
			m.EnableKeyword(keyword);
		else
			m.DisableKeyword(keyword);
	}

	public override void AssignNewShaderToMaterial(Material mat, Shader oldShader, Shader newShader) {
		m_FirstTimeApply = true;
		if (mat.HasProperty("_Emission"))
			mat.SetColor("_EmissionColor", mat.GetColor("_Emission"));
		base.AssignNewShaderToMaterial(mat, oldShader, newShader);
		SetBlendMode(mat, mat.GetInt("_BlendMode"));
		ApplyMaterialSettings(mat);
	}

	void SetBlendMode(Material material, int blendMode){
		switch (blendMode){
			case 0:
				material.SetOverrideTag("RenderType", "");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.renderQueue = -1;
				break;

			case 1:
				material.SetOverrideTag("RenderType", "TransparentCutout");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
				break;

			case 2:
				material.SetOverrideTag("RenderType", "TransparentCutout");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
				break;

			case 3:
				material.SetOverrideTag("RenderType", "Transparent");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
				material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
				break;

			case 4:
				material.SetOverrideTag("RenderType", "Transparent");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
				break;

			default: break;
		}
	}

	void ResetBase(){
		_BlendMode.floatValue = 0f;
		_Cutoff.floatValue = 0.5f;
		_Color.colorValue = new Color(0.8f,0.95f,1f,1f);
		_Invert.floatValue = 0f;
		_Smoothstep.floatValue = 0f;
		_Culling.floatValue = 2f;
		_BumpScale.floatValue = 1f;
		_EmissInvert.floatValue = 1f;
		_MainTex.textureValue = null;
		_BumpMap.textureValue = null;
		_EmissTex.textureValue = null;
	}

	void ResetLighting(){
		_EnableSH.floatValue = 0f;
		_EnableReflections.floatValue = 0f;
		_Metallic.floatValue = 0f;
		_Roughness.floatValue = 1f;
		_ReflectionStr.floatValue = 1f;
		_MetallicMap.textureValue = null;
		_RoughnessMap.textureValue = null;
		_ReflectionMask.textureValue = null;
	}

	void ResetRim(){
		_RimBrightness.floatValue = 1f;
		_RimWidth.floatValue = 0.5f;
		_RimEdge.floatValue = 0f;
		_RimGradMask.floatValue = 1f;
		_RimMask.textureValue = null;
	}

	void ResetEmission(){
		_EmissStr.floatValue = 1f;
		_EmissPow.floatValue = 1f;
		_EmissGradMasking.floatValue = 0.99f;
		_EmissGradMask.textureValue = null;
	}

	void ResetGradient(){
		_GradientInvert.floatValue = 0f;
		_GradientAxis.floatValue = 1f;
		_GradientNoiseScale.vectorValue = new Vector4(5,5,5,0);
		_GradientBrightness.floatValue = 1f;
		_GradientHeightMax.floatValue = 0f;
		_GradientHeightMin.floatValue = -1f;
		_GradientSpeed.floatValue = 0.01f;
		_GradientContrast.floatValue = 1.5f;
		_GradientMask.textureValue = null;
	}

	void ResetNoise(){
		_NoiseScale.vectorValue = new Vector4(50,50,0,0);
		_NoiseBrightness.floatValue = 1f;
		_NoiseCutoff.floatValue = 0.73f;
		_NoiseSmooth.floatValue = 0.01f;
		_NoiseMask.textureValue = null;
	}

	void ResetDissolve(){
		_DissolveAmt.floatValue = 0f;
		_DissolveRimBrightness.floatValue = 1f;
		_DissolveRimWidth.floatValue = 2f;
		_DissolveTex.textureValue = null;
	}

	void ResetOutline(){
		_InvertedOutline.floatValue = 1f;
		_StencilOutline.floatValue = 0f;
		_Thickness.floatValue = 0.1f;
		_OutlineMask.textureValue = null;
	}

	void ClearDictionaries(){
		baseTabButtons.Clear();
		lightingTabButtons.Clear();
		gradientTabButtons.Clear();
		noiseTabButtons.Clear();
		outlineTabButtons.Clear();
		rimTabButtons.Clear();
		dissolveTabButtons.Clear();
		emissTabButtons.Clear();
	}
}