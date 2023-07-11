using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
#if UNITY_EDITOR
using UnityEditor;

#endif

[ExecuteInEditMode]
public class InstancedFurDrawer : MonoBehaviour
{
    // public float range;
    [Header("Settings")]
    // [GUIColor(209/256,115/256,142/256,1)]
    public float drawFarDistance = 125;

    public Material material;
    public bool willDraw = true;


    public bool hasInit = false;
    private ComputeBuffer meshPropertiesBuffer;
    private ComputeBuffer argsBuffer;
    private uint[] args;
    private ComputeBuffer allInstancesPosWSBuffer;
    private ComputeBuffer visibleInstancesOnlyPosWSIDBuffer;

    private List<int> visibleCellIDList = new List<int>();
    private Plane[] cameraFrustumPlanes = new Plane[6];

    public Mesh mesh;
    private int population;
    public InstancedFurData FurData;
    private Bounds bounds;

    private List<Vector3> m_PositionWS;

    // private List<float> m_SizeWS;
    private List<Quaternion> m_RotationWS;
    private List<Vector3> m_ScaleWS;
    private List<Vector2> m_UVs;
    private List<Vector3> m_Normal;
    private Camera cam;
    private float minX, minZ, maxX, maxZ;
    private List<MeshProperties> properties = new List<MeshProperties>();

#if UNITY_EDITOR
    [Button("刷新全部数据", ButtonSizes.Large)]
    public void RefreshAll()
    {
        if (FurData)
        {
            FurData.SaveData(true);
            EditorUtility.SetDirty(FurData);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }

    [Button("刷新部分数据", ButtonSizes.Large)]
    public void Refresh()
    {
        if (FurData)
        {
            FurData.SaveData();
            EditorUtility.SetDirty(FurData);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }
#endif
    private struct MeshProperties
    {
        public Matrix4x4 mat;
        public Vector3 normal;
        public Vector2 uv;

        public static int Size()
        {
            return
                sizeof(float) * 4 * 4 + // matrix;
                sizeof(float) * 3 + // normal;
                sizeof(float) * 2; // uv;
        }
    }

    private void Setup()
    {
        m_PositionWS = new List<Vector3>();
        m_RotationWS = new List<Quaternion>();
        m_ScaleWS = new List<Vector3>();
        m_Normal = new List<Vector3>();
        m_UVs = new List<Vector2>();
        cam = Camera.main;
        hasInit = false;
        InitializeBuffers();
        hasInit = true;
        bounds = new Bounds(cam.transform.position, new Vector3(400.0f, 400.0f, 400.0f));
    }

    private void InitializeBuffers()
    {
        if (hasInit)
            return;

        m_PositionWS.Clear();
        m_RotationWS.Clear();
        m_ScaleWS.Clear();
        m_Normal.Clear();
        m_UVs.Clear();
        var furList = FurData.allFurs;
        for (int i = 0; i < furList.Count; i++)
        {
            m_PositionWS.AddRange(furList[i].m_PositionWS);
            m_RotationWS.AddRange(furList[i].m_RotationWS);
            m_ScaleWS.AddRange(furList[i].m_ScaleWS);
            m_Normal.AddRange(furList[i].m_Normal);
            m_UVs.AddRange(furList[i].m_UVs);
        }


        population = m_PositionWS.Count;
        if (population < 1)
            return;

        if (visibleInstancesOnlyPosWSIDBuffer != null)
            visibleInstancesOnlyPosWSIDBuffer.Release();
        visibleInstancesOnlyPosWSIDBuffer =
            new ComputeBuffer(population, sizeof(uint), ComputeBufferType.Append); //uint only, per visible grass


        // Argument buffer used by DrawMeshInstancedIndirect.
        args = new uint[5] {0, 0, 0, 0, 0};
        args[0] = (uint) mesh.GetIndexCount(0);
        args[1] = (uint) population;
        args[2] = (uint) mesh.GetIndexStart(0);
        args[3] = (uint) mesh.GetBaseVertex(0);
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);


        properties.Clear();
        for (int i = 0; i < population; i++)
        {
            MeshProperties props = new MeshProperties();
            props.mat = Matrix4x4.TRS(m_PositionWS[i], m_RotationWS[i], m_ScaleWS[i]);
            props.normal = m_Normal[i];
            props.uv = m_UVs[i];
            // props.normal = m_Normal[i];
            properties.Add(props);
            // properties[i] = props;
        }

        meshPropertiesBuffer = new ComputeBuffer(population, MeshProperties.Size());
        meshPropertiesBuffer.SetData(properties);
        // compute.SetBuffer(kernel, "_Properties", meshPropertiesBuffer);
        material.SetBuffer("_FurProperties", meshPropertiesBuffer);
        material.SetBuffer("_VisibleInstanceOnlyTransformIDBuffer", visibleInstancesOnlyPosWSIDBuffer);
        hasInit = true;
    }


    private void Start()
    {
        Setup();
    }

    public bool IsPointInFrustum(Vector3 point, Plane[] planes)
    {
        for (int i = 0, iMax = planes.Length; i < iMax; ++i)
        {
            //判断一个点是否在平面的正方向上
            if (!planes[i].GetSide(point))
            {
                return false;
            }
        }

        return true;
    }


    void LateUpdate()
    {
        if (!willDraw)
            return;
        InitializeBuffers();
        visibleCellIDList.Clear();


        float cameraOriginalFarPlane = cam.farClipPlane;
        float cameraOriginalNearPlane = cam.fieldOfView;
        cam.farClipPlane = drawFarDistance;
        cam.fieldOfView += 10;
        GeometryUtility.CalculateFrustumPlanes(cam, cameraFrustumPlanes);
        cam.farClipPlane = cameraOriginalFarPlane;
        cam.fieldOfView -= 10;

        for (int i = 0; i < population; i++)
        {
            if (IsPointInFrustum(m_PositionWS[i], cameraFrustumPlanes))
            {
                visibleCellIDList.Add(i);
            }
        }

    
        if (visibleCellIDList.Count == 0)
            return;
        
        // meshPropertiesBuffer.SetCounterValue(0);
        // properties.Clear();
        // properties = new MeshProperties[visibleCellIDList.Count];
        for (int i = 0; i < visibleCellIDList.Count; i++)
        {
            int id = visibleCellIDList[i];
            MeshProperties props = properties[i];
            // MeshProperties props = new MeshProperties();
            props.mat = Matrix4x4.TRS(m_PositionWS[id], m_RotationWS[id], m_ScaleWS[id]);
            props.normal = m_Normal[id];
            props.uv = m_UVs[id];
            properties[i] = props;
        }


        // meshPropertiesBuffer = new ComputeBuffer(visibleCellIDList.Count, MeshProperties.Size());
        meshPropertiesBuffer.SetData(properties);
        material.SetBuffer("_FurProperties", meshPropertiesBuffer);

        args[1] = (uint) visibleCellIDList.Count;

        argsBuffer.SetData(args);

        ComputeBuffer.CopyCount(meshPropertiesBuffer, argsBuffer, 4);
        bounds.center = cam.transform.position;
        Graphics.DrawMeshInstancedIndirect(mesh, 0, material, bounds, argsBuffer);
    }

    private void OnDestroy()
    {
        hasInit = false;
        if (meshPropertiesBuffer != null)
        {
            meshPropertiesBuffer.Release();
        }

        meshPropertiesBuffer = null;

        if (argsBuffer != null)
        {
            argsBuffer.Release();
        }

        argsBuffer = null;
        visibleCellIDList.Clear();
    }
}

