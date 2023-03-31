using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

using UnityEditor.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Assertions;
using UnityEditor.AnimatedValues;
using UnityEditor.Rendering;
namespace H3d.InstancedFur
{

     public static class FurMaterialEditor
        {
            //Section toggles
            public class Section
            {
                private const float ANIMATION_SPEED = 16f;
                
                public bool Expanded
                {
                    get { return SessionState.GetBool(id, false); }
                    set { SessionState.SetBool(id, value); }
                }

                public AnimBool anim;

                private readonly string id;
                public string title;

                public Section(MaterialEditor target, string id, string title)
                {
                    this.id = "SGS_" + id + "_SECTION";
                    this.title = title;

                    anim = new AnimBool(false);
                    anim.valueChanged.AddListener(target.Repaint);
                    anim.speed = ANIMATION_SPEED;
                }
                
             
                
                public void SetTarget()
                {
                    anim.target = Expanded;
                }
            }
            public static void DrawVector3(MaterialProperty prop, string name, string tooltip = null)
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.PrefixLabel(new GUIContent(name, tooltip));
                    GUILayout.Space(-15f);
                    prop.vectorValue = EditorGUILayout.Vector3Field(new GUIContent("", null, tooltip), prop.vectorValue);
                }
            }
           
            public static bool DrawHeader(string title, bool isExpanded, Action clickAction = null)
            {
                CoreEditorUtils.DrawSplitter();

                var backgroundRect = GUILayoutUtility.GetRect(1f, 25f);
 
                var labelRect = backgroundRect;
                labelRect.xMin += 8f;
                labelRect.xMax -= 20f + 16 + 5;

                var foldoutRect = backgroundRect;
                
                foldoutRect.xMin -= 8f;
                foldoutRect.y += 0f;
                foldoutRect.width = 25f;
                foldoutRect.height = 25f;

                // Background rect should be full-width
                backgroundRect.xMin = 0f;
                backgroundRect.width += 4f;

                // Background
                float backgroundTint = EditorGUIUtility.isProSkin ? 0.1f : 1f;
                EditorGUI.DrawRect(backgroundRect, new Color(backgroundTint, backgroundTint, backgroundTint, 0.2f));

                // Title
                EditorGUI.LabelField(labelRect, title, EditorStyles.boldLabel);

                // Foldout
                isExpanded = GUI.Toggle(foldoutRect, isExpanded, new GUIContent(isExpanded ? "−" : "≡"), EditorStyles.boldLabel);

                // Context menu

                var menuIcon = CoreEditorStyles.paneOptionsIcon;

                var menuRect = new Rect(labelRect.xMax + 3f + 16 + 5, labelRect.y + 1f, menuIcon.width, menuIcon.height);

                //if (clickAction != null)
                //GUI.DrawTexture(menuRect, menuIcon);

                // Handle events
                var e = Event.current;

                if (e.type == EventType.MouseDown)
                {
                    if (clickAction != null && menuRect.Contains(e.mousePosition))
                    {
                        e.Use();
                    }
                    else if (labelRect.Contains(e.mousePosition))
                    {
                        if (e.button == 0)
                        {
                            isExpanded = !isExpanded;
                            if (clickAction != null) clickAction.Invoke();
                        }

                        e.Use();
                    }
                }

                return isExpanded;
            }
        }
        
    public class MaterialUI : ShaderGUI
    {

        public MaterialEditor materialEditor;

        private Vector4 windParams;

        private MaterialProperty _BaseMap;
        private MaterialProperty _Cutoff;
        private MaterialProperty _InnerCutoff;
        private MaterialProperty _ShadowCutoff;
        private MaterialProperty _BaseColor;


        private MaterialProperty _HueVariation;
        private MaterialProperty _OcclusionStrength;

        // private MaterialProperty _Smoothness;
        // private MaterialProperty _DarkMin;
        private MaterialProperty _Transparent;
        private MaterialProperty _InnerTransparent;
        private MaterialProperty _TranslucencyDirect;
        private MaterialProperty _TranslucencyIndirect;

        private MaterialProperty _NormalFlattening;
        private MaterialProperty _NormalSpherify;
        private MaterialProperty _NormalSpherifyMask;
 
        private MaterialProperty scalemapInfluence;

        private MaterialProperty _WindAmbientStrength;
        private MaterialProperty _GravityStrength;
        private MaterialProperty _PushRadius;
        private MaterialProperty _Strength;
        private MaterialProperty _WindSpeed;
        private MaterialProperty _WindDirection;
        private MaterialProperty _FurDirection;
        private MaterialProperty _WindVertexRand;
        private MaterialProperty _WindObjectRand;
        private MaterialProperty _WindRandStrength;
        private MaterialProperty _WindSwinging;
        private MaterialProperty _WindMap;
        private MaterialProperty _ScaleMap;
        private MaterialProperty _WindGustStrength;
        private MaterialProperty _WindGustFreq;

        private MaterialProperty _Cull;

        private MaterialProperty _ReceiveShadows;

        
        private FurMaterialEditor.Section renderingSection;
        private FurMaterialEditor.Section mapsSection;
        private FurMaterialEditor.Section colorSection;
        private FurMaterialEditor.Section shadingSection;
        private FurMaterialEditor.Section verticesSection;
        private FurMaterialEditor.Section windSection;

        private bool initialized;

        private void OnEnable(MaterialEditor materialEditorIn)
        {
            renderingSection = new FurMaterialEditor.Section(materialEditorIn, "RENDERING", "Rendering");
            mapsSection = new FurMaterialEditor.Section(materialEditorIn,"MAPS", "Main maps");
            colorSection = new FurMaterialEditor.Section(materialEditorIn,"COLOR", "Color");
            shadingSection = new FurMaterialEditor.Section(materialEditorIn,"SHADING", "Shading");
            verticesSection = new FurMaterialEditor.Section(materialEditorIn,"VERTICES", "Vertices");
            windSection = new FurMaterialEditor.Section(materialEditorIn,"WIND", "Wind");

            foreach (var obj in materialEditorIn.targets)
            {
                MaterialChanged((Material)obj);
            }
        }
        public void FindProperties(MaterialProperty[] props, Material material)
        {
            windParams = Shader.GetGlobalVector("_GlobalWindParams");
            
            _Cull = FindProperty("_Cull", props);
            
            _BaseMap = FindProperty("_BaseMap", props);
            _Cutoff = FindProperty("_Cutoff", props);
            _InnerCutoff = FindProperty("_InnerCutoff", props);
            _ShadowCutoff = FindProperty("_ShadowCutoff", props);
            _BaseColor = FindProperty("_BaseColor", props);
            _HueVariation = FindProperty("_HueVariation", props);
            
            scalemapInfluence = FindProperty("_ScalemapInfluence", props);

            _OcclusionStrength = FindProperty("_OcclusionStrength", props);
            _Transparent = FindProperty("_Transparent", props);
            _InnerTransparent = FindProperty("_InnerTransparent", props);
            _TranslucencyDirect = FindProperty("_TranslucencyDirect", props);
            _TranslucencyIndirect = FindProperty("_TranslucencyIndirect", props);

            _NormalFlattening = FindProperty("_NormalFlattening", props);
            _NormalSpherify = FindProperty("_NormalSpherify", props);
            _NormalSpherifyMask = FindProperty("_NormalSpherifyMask", props);

            _WindAmbientStrength = FindProperty("_WindAmbientStrength", props);
            _GravityStrength = FindProperty("_GravityStrength", props);
            _PushRadius = FindProperty("_PushRadius", props);
            _Strength = FindProperty("_Strength", props);
            
            _WindSpeed = FindProperty("_WindSpeed", props);
            _WindDirection = FindProperty("_WindDirection", props);
            _FurDirection = FindProperty("_FurDirection", props);
            _WindVertexRand = FindProperty("_WindVertexRand", props);
            _WindObjectRand = FindProperty("_WindObjectRand", props);
            _WindRandStrength = FindProperty("_WindRandStrength", props);
            _WindSwinging = FindProperty("_WindSwinging", props);

            _WindMap = FindProperty("_WindMap", props);
            _ScaleMap = FindProperty("_ScaleMap", props);
            _WindGustStrength = FindProperty("_WindGustStrength", props);
            _WindGustFreq = FindProperty("_WindGustFreq", props);
            _ReceiveShadows = FindProperty("_ReceiveShadows", props);


        }


        public override void OnClosed(Material material)
        {
            initialized = false;
        }

         public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] props)
        {
            
            this.materialEditor = materialEditorIn;

            materialEditor.SetDefaultGUIWidths();
            materialEditor.UseDefaultMargins();
            EditorGUIUtility.labelWidth = 0f;

            Material material = materialEditor.target as Material;
            FindProperties(props, material);

            
            if (!initialized)
            {
                OnEnable(materialEditor);
                initialized = true;
            }

            ShaderPropertiesGUI(material);
            
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("- Staggart Creations -", EditorStyles.centeredGreyMiniLabel);

        }

        public void ShaderPropertiesGUI(Material material)
        {
            EditorGUI.BeginChangeCheck();
            
            DrawHeader();
            
            EditorGUILayout.Space();
            
            DrawRendering();
            DrawMaps();
            DrawColor();
            DrawShading();
            DrawVertices(material);
            DrawWind();
            
            EditorGUILayout.Separator();
            
            DrawStandardFields(material);
            
            EditorGUILayout.Space();


            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in  materialEditor.targets)
                    MaterialChanged((Material)obj);
            }
        }

        public void MaterialChanged(Material material)
        {
            if (material == null) throw new ArgumentNullException("material");

            SetMaterialKeywords(material);
        }

        private void SetMaterialKeywords(Material material)
        {
            // Clear all keywords for fresh start
            material.shaderKeywords = null;
            
            material.SetTexture("_BaseMap", _BaseMap.textureValue);
            material.SetTexture("_WindMap", _WindMap.textureValue);
            material.SetTexture("_ScaleMap", _ScaleMap.textureValue);
 
            CoreUtils.SetKeyword(material, "_RECEIVE_SHADOWS_OFF", material.GetFloat("_ReceiveShadows") == 0.0f);
 

        }

        private void DrawHeader()
        {


        }
        
        private void DrawRendering()
        {
            renderingSection.Expanded = FurMaterialEditor.DrawHeader(renderingSection.title, renderingSection.Expanded, () => SwitchSection(renderingSection));
            renderingSection.SetTarget();

            if (EditorGUILayout.BeginFadeGroup(renderingSection.anim.faded))
            {
                EditorGUILayout.Space();
                materialEditor.ShaderProperty(_Cull, _Cull.displayName);
                materialEditor.ShaderProperty(_ReceiveShadows, new GUIContent("Receive shadows", "Apply shadows cast by other objects onto this material.\n\nShadow casting behaviour can be set on a per Mesh Renderer basis."));
                EditorGUILayout.Space();

            }
            EditorGUILayout.EndFadeGroup();
            
        }

        private void DrawMaps()
        {
            mapsSection.Expanded = FurMaterialEditor.DrawHeader(mapsSection.title, mapsSection.Expanded, () => SwitchSection(mapsSection));
            mapsSection.SetTarget();

            if (EditorGUILayout.BeginFadeGroup(mapsSection.anim.faded))
            {
                EditorGUILayout.Space();
                
                materialEditor.TextureProperty(_BaseMap, "Texture (A=Alpha)");
                materialEditor.ShaderProperty(_Cutoff, "Alpha clipping");
                materialEditor.ShaderProperty(_InnerCutoff, "Inner Alpha clipping");
                materialEditor.ShaderProperty(_ShadowCutoff, "Shadow clipping");

                EditorGUILayout.Space();
            }
            EditorGUILayout.EndFadeGroup();
        }

        private void DrawColor()
        {
            colorSection.Expanded = FurMaterialEditor.DrawHeader(colorSection.title, colorSection.Expanded, () => SwitchSection(colorSection));
            colorSection.SetTarget();

            if (EditorGUILayout.BeginFadeGroup(colorSection.anim.faded))
            {
                EditorGUILayout.Space();

                materialEditor.ShaderProperty(_BaseColor, new GUIContent(_BaseColor.displayName, "This color is multiplied with the texture. "));
                materialEditor.ShaderProperty(_HueVariation, new GUIContent(_HueVariation.displayName, "Every object will receive a random color between this color, and the main color. The alpha channel controls the intensity"));
              
                EditorGUILayout.Space();

                materialEditor.ShaderProperty(_OcclusionStrength, new GUIContent(_OcclusionStrength.displayName, "Darkens the mesh based on the red vertex color painted into the mesh"));

           
                EditorGUILayout.Space();

            }
            EditorGUILayout.EndFadeGroup();
        }

        private void DrawShading()
        {
            shadingSection.Expanded =FurMaterialEditor.DrawHeader(shadingSection.title, shadingSection.Expanded, () => SwitchSection(shadingSection));
            shadingSection.SetTarget();

            if (EditorGUILayout.BeginFadeGroup(shadingSection.anim.faded))
            {
                EditorGUILayout.Space();


                EditorGUILayout.LabelField(new GUIContent("Translucency"), EditorStyles.boldLabel);
                materialEditor.TexturePropertySingleLine(new GUIContent("Scale texture"), _ScaleMap);
                FurMaterialEditor.DrawVector3(scalemapInfluence, "Scale influence", "Controls the scale strength of the heightmap per axis");
                
                materialEditor.ShaderProperty(_Transparent, new GUIContent("Transparent", ""));
                materialEditor.ShaderProperty(_InnerTransparent, new GUIContent("InnerTransparent", ""));
                materialEditor.ShaderProperty(_TranslucencyDirect, new GUIContent("Direct (back)", "Simulates sun light passing through the fur. Most noticeable at glancing or low sun angles\n\nControls the strength of light hitting the BACK"));
                materialEditor.ShaderProperty(_TranslucencyIndirect, new GUIContent("Indirect (front)", "Simulates sun light passing through the fur. Most noticeable at glancing or low sun angles\n\nControls the strength of light hitting the FRONT"));
                
                // materialEditor.ShaderProperty(_TranslucencyFalloff, new GUIContent("Exponent", "Controls the size of the effect"));
                // materialEditor.ShaderProperty(_TranslucencyOffset, new GUIContent("Offset", "Controls how much the effect wraps around the mesh. This at least requires spherical normals to take effect"));

                EditorGUILayout.Space();

                EditorGUILayout.LabelField(new GUIContent("Normals", "Normals control the orientation of the vertices for lighting effect"), EditorStyles.boldLabel);
                // materialEditor.ShaderProperty(_DarkMin, new GUIContent("DarkMin", "Gradually has the normals point straight up, this will help match the shading to the surface the fur is placed on."));
                materialEditor.ShaderProperty(_NormalFlattening, new GUIContent("Flatten normals (lighting)", "Gradually has the normals point straight up, this will help match the shading to the surface the fur is placed on."));
                materialEditor.ShaderProperty(_NormalSpherify, new GUIContent("Spherify normals", "Gradually has the normals point away from the object's pivot point. For fur this results in fluffy-like shading"));
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(_NormalSpherifyMask, new GUIContent("Tip mask", "Only apply spherifying to the top of the mesh (based on the red vertex color channel of the mesh"));
                EditorGUI.indentLevel--;
                
              
                EditorGUILayout.Space();

            }
            EditorGUILayout.EndFadeGroup();
        }

        private void DrawVertices(Material material)
        {
            verticesSection.Expanded =FurMaterialEditor.DrawHeader(verticesSection.title, verticesSection.Expanded, () => SwitchSection(verticesSection));
            verticesSection.SetTarget();

            if (EditorGUILayout.BeginFadeGroup(verticesSection.anim.faded))
            {
                EditorGUILayout.Space();
    
                EditorGUILayout.LabelField("Gravity", EditorStyles.boldLabel);
                materialEditor.ShaderProperty(_FurDirection, new GUIContent(_FurDirection.displayName, "The Y and W components are unused"));
                materialEditor.ShaderProperty(_GravityStrength, new GUIContent(_GravityStrength.displayName, ""));
                materialEditor.ShaderProperty(_PushRadius, new GUIContent(_PushRadius.displayName, ""));
                materialEditor.ShaderProperty(_Strength, new GUIContent(_Strength.displayName, ""));
                
                EditorGUILayout.Space();

            }
            EditorGUILayout.EndFadeGroup();
        }

        private void DrawWind()
        {
            windSection.Expanded = FurMaterialEditor.DrawHeader(windSection.title, windSection.Expanded, () => SwitchSection(windSection));
            windSection.SetTarget();

            if (EditorGUILayout.BeginFadeGroup(windSection.anim.faded))
            {
                EditorGUILayout.Space();
               
                EditorGUILayout.LabelField("Wind", EditorStyles.boldLabel);
                if (windParams.x > 0f) EditorGUILayout.HelpBox("Wind strength and speed is influenced by a Wind Zone component", MessageType.Info);
        
                materialEditor.ShaderProperty(_WindAmbientStrength, new GUIContent(_WindAmbientStrength.displayName, "The amount of wind that is applied without gusting"));
                materialEditor.ShaderProperty(_WindSpeed, new GUIContent(_WindSpeed.displayName, "The speed the wind and gusting moves at"));
                materialEditor.ShaderProperty(_WindDirection, new GUIContent(_WindDirection.displayName, "The Y and W components are unused"));
               
                materialEditor.ShaderProperty(_WindSwinging, new GUIContent(_WindSwinging.displayName, "Controls the amount the fur is able to spring back against the wind direction"));

                EditorGUILayout.Space();

                EditorGUILayout.LabelField("Randomization", EditorStyles.boldLabel);
                materialEditor.ShaderProperty(_WindObjectRand, new GUIContent("Per-object", "Adds a per-object offset, making each object move randomly rather than in unison"));
                materialEditor.ShaderProperty(_WindVertexRand, new GUIContent("Per-vertex", "Adds a per-vertex offset"));
                materialEditor.ShaderProperty(_WindRandStrength, new GUIContent(_WindRandStrength.displayName, "Gives each object a random wind strength. This is useful for breaking up repetition and gives the impression of turbulence"));

                EditorGUILayout.Space();

                EditorGUILayout.LabelField("Gusting", EditorStyles.boldLabel);
                materialEditor.TexturePropertySingleLine(new GUIContent("Gust texture (Grayscale)"), _WindMap);
              
                materialEditor.ShaderProperty(_WindGustStrength, new GUIContent("Strength", "Gusting add wind strength based on the gust texture, which moves over the fur"));
                materialEditor.ShaderProperty(_WindGustFreq, new GUIContent("Frequency", "Controls the tiling of the gusting texture, essentially setting the size of the gusting waves"));
                // materialEditor.ShaderProperty(_WindGustTint, new GUIContent("Max. Color tint", "Uses the gusting texture to add a brighter tint based on the gusting strength"));

                EditorGUILayout.Space();

            }
            EditorGUILayout.EndFadeGroup();
        }

        private void DrawStandardFields(Material material)
        {
            EditorGUILayout.LabelField("Native settings", EditorStyles.boldLabel);

            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
            if (!materialEditor.IsInstancingEnabled()) EditorGUILayout.HelpBox("GPU Instancing is highly recommended for optimal performance", MessageType.Warning);
            materialEditor.DoubleSidedGIField();
            materialEditor.LightmapEmissionProperty();
        }
       
        private void SwitchSection(FurMaterialEditor.Section s)
        {
            /*
            renderingSection.Expanded = (s == renderingSection) ? !renderingSection.Expanded : false;
            mapsSection.Expanded = (s == mapsSection) ? !mapsSection.Expanded : false;
            colorSection.Expanded = (s == colorSection) ? !colorSection.Expanded : false;
            shadingSection.Expanded = (s == shadingSection) ? !shadingSection.Expanded : false;
            verticesSection.Expanded = (s == verticesSection) ? !verticesSection.Expanded : false;
            windSection.Expanded = (s == windSection) ? !windSection.Expanded : false;
            */
        }


    }

}