using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;


public class MeshSubdivisionEditor : EditorWindow
{
    public MeshSubdivisionEditor() {
        titleContent.text = "H3D/Subdivision";
    }
    
    float iterations = 1;
    Vector2 selectionScroll = Vector2.zero;
    private Transform selection;

    private Mesh orignalMesh;
    private Mesh newMesh;
    private string path;
 
    private bool hasSubdivition = false;
    // List<Mesh> meshList = new List<Mesh>();
    void OnGUI()
    {
        EditorGUIUtility.labelWidth = 80;
        if (selection == null)
        {
            EditorGUILayout.HelpBox("未选择有效物体",MessageType.Error);
            return;
        }
        
        if (selection != Selection.activeTransform)
        {
            if (selection&&hasSubdivition)
            {
                MeshFilter meshFilter = SubdivisionUtility.CheckMeshFilter(selection.gameObject);
                meshFilter.sharedMesh = orignalMesh;
            }
            hasSubdivition = false;
           
         
            selection = Selection.activeTransform;
        }
        
       
          
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Selection", GUILayout.Width(80));
        // selectionScroll = EditorGUILayout.BeginScrollView(selectionScroll);
        
        EditorGUILayout.LabelField(selection.name);
        MeshFilter mf = SubdivisionUtility.CheckMeshFilter(selection.gameObject);
        // EditorGUILayout.EndScrollView();
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.HelpBox("数值越大细分程度越大",MessageType.Info);
        iterations = EditorGUILayout.Slider("Iterations", iterations, 0, 1);
        if (!hasSubdivition)
        {
           
            if (GUILayout.Button("Subdivide"))
            {
                if (selection == null) throw new System.Exception("Nothing selected to subdivide");
                Undo.RecordObject(mf, "Subdivide " + selection.name);
                // Subdivide
                orignalMesh =  SubdivisionUtility.CheckMeshFilter(selection.gameObject).sharedMesh;
                newMesh = SubdivisionUtility.Subdivide(selection.gameObject, iterations);
                hasSubdivition = true;
            }

        }
        else
        {
            if (GUILayout.Button("Reset"))
            {
                mf.sharedMesh = orignalMesh;
                hasSubdivition = false;
            }
            
        }

        if (path ==null)
        {
            
            Scene scene = SceneManager.GetActiveScene();
            path = scene.path.Substring(0,scene.path.LastIndexOf('/'));
       
        }
        EditorGUILayout.LabelField(path);
        GUILayout.BeginHorizontal();
       
        if (GUILayout.Button("Choose Path"))
        {
            string choosePath = EditorUtility.SaveFolderPanel(
                "Save New Mesh",
                "",""
                );
            if (choosePath.Length == 0)
            {
                return;
            }
            
            path = choosePath.Substring(choosePath.IndexOf("Assets/"));
;
        }
        if (GUILayout.Button("Save"))
        {
            
            string savePath = path + "/" + mf.name + "_fur.asset";
            AssetDatabase.CreateAsset(newMesh, savePath );

            mf.sharedMesh = newMesh;

            SceneView.RepaintAll();
            hasSubdivition = false;
        }
        GUILayout.EndHorizontal();
     
    }
    void OnInspectorUpdate() {

        Repaint();
    }
   
     
     [MenuItem("H3D/Subdivision")]
     static void ShowSubdivisionUtility() {
         if (window == null) {
             window = ScriptableObject.CreateInstance<MeshSubdivisionEditor>();
         }
         window.ShowUtility();

     }
     static private MeshSubdivisionEditor window = null;
}