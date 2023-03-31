using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;
// using NUnit.Framework.Interfaces;
using Random = UnityEngine.Random;
[System.Serializable] 
public struct SingleFur
{
    public List<Vector3> m_PositionWS;
    public List<Quaternion> m_RotationWS;
    public List<Vector3> m_ScaleWS;
    public List<Vector2> m_UVs;
    public List<Vector3> m_Normal;
    public Vector3 position;
    public float RotateRange;
    public Transform transform;
    // public Bounds bounds;
    // public int startID, endID;
};

public class InstancedFurManager
{
    #region singleton stuff

    #endregion

    static readonly Lazy<InstancedFurManager> s_Instance =
        new Lazy<InstancedFurManager>(() => new InstancedFurManager());

    public static InstancedFurManager Instance => s_Instance.Value;
    List<InstancedFurComponent> m_InstancedFurs = new List<InstancedFurComponent>();
    List<SingleFur> FurList = new List<SingleFur>();
    private float minX, minZ, maxX, maxZ;

    InstancedFurManager()
    {
        m_InstancedFurs = new List<InstancedFurComponent>();
    }

    public void Clear()
    {
        m_InstancedFurs.Clear();
    }

    public void Register(InstancedFurComponent fur)
    {
        m_InstancedFurs.Add(fur);
    }

    public void Unregister(InstancedFurComponent fur)
    {
        m_InstancedFurs.Remove(fur);
    }

    public List<InstancedFurComponent> GetFurs()
    {
        return m_InstancedFurs;
    }


    public List<SingleFur> GetFurList()
    {
        return FurList;
    }

    Vector3 quat_rot(Vector4 q, Vector3 v)
    {
        var ror = new Vector3(q.x, q.y, q.z);
        var a = Vector3.Dot(ror, v) * ror + q.w * q.w * v;
        var b = 2 * q.w * Vector3.Cross(ror, v);
        var c = Vector3.Cross(Vector3.Cross(ror, v), ror);
        return a + b - c;
    }

    public void UpdateAllList()
    {
        Reset();


        // foreach (InstancedFurComponent instancedFur in m_InstancedFurs) 
        for (int index = 0; index < m_InstancedFurs.Count; index++)
        {
            InstancedFurComponent instancedFur = m_InstancedFurs[index];

            instancedFur.index = index;
            Transform furTrans = instancedFur.transform;
            var mesh = furTrans.GetComponent<MeshFilter>().sharedMesh;

            SingleFur _fur = new SingleFur();

            _fur.m_PositionWS = new List<Vector3>();
            _fur.m_RotationWS = new List<Quaternion>();
            _fur.m_ScaleWS = new List<Vector3>();
            _fur.m_UVs = new List<Vector2>();
            _fur.m_Normal = new List<Vector3>();


            // _fur.startID = positionWS.Count;
            _fur.position = furTrans.position;
            _fur.transform = furTrans;

            // _fur.bounds = mesh.bounds;
            var RotationRange = instancedFur.rotationRange;
            var ScaleRange = instancedFur.scaleRange;
            var Offset = instancedFur.offset;
            var scale = instancedFur.scale == Vector3.zero ? Vector3.one : instancedFur.scale;
            int vertexCount = mesh.vertexCount;
            var vertexColorArray = mesh.colors;
            var transRor = furTrans.rotation.normalized;

            minX = float.MaxValue;
            minZ = float.MaxValue;
            maxX = float.MinValue;
            maxZ = float.MinValue;
            // float sizeX =  mesh.bounds.extents.x;
            // float sizeZ =  mesh.bounds.extents.z;
            for (int i = 0; i < vertexCount; i++)
            {
                Vector3 target = mesh.vertices[i];
                minX = Mathf.Min(target.x, minX);
                minZ = Mathf.Min(target.z, minZ);
                maxX = Mathf.Max(target.x, maxX);
                maxZ = Mathf.Max(target.z, maxZ);
            }


            for (int i = 0; i < vertexCount; i++)
            {
                float posOs_X = Mathf.Abs(mesh.vertices[i].x - minX) / (maxX - minX);
                float posOs_Z = Mathf.Abs(mesh.vertices[i].z - minZ) / (maxZ - minZ);

                //Postion
                var localPosition = new Vector3(mesh.vertices[i].x * furTrans.lossyScale.x,
                                        (mesh.vertices[i].y) * furTrans.lossyScale.y,
                                        mesh.vertices[i].z * furTrans.lossyScale.z) +
                                    mesh.normals[i] * Offset;

                var Pos = quat_rot(new Vector4(transRor.x, transRor.y, transRor.z, transRor.w), localPosition);
                Vector3 position = Pos + furTrans.position;


                //Rotation
                var normalRor = quat_rot(new Vector4(transRor.x, transRor.y, transRor.z, transRor.w), mesh.normals[i]);

                var ror = Quaternion.FromToRotation(new Vector3(0, 1, 0), normalRor.normalized);
                var randomRor = Quaternion.Euler(0, Random.Range(-RotationRange, RotationRange), 0);
                Quaternion rotation = ror * randomRor;
                float vetexColor = ScaleRange;

                if (vertexColorArray.Length > 0)
                    vetexColor = vertexColorArray[i].r * ScaleRange + 0.3f;
                //Scale
                Vector3 scaleR = new Vector3(scale.x * vetexColor, scale.y * vetexColor, scale.z * vetexColor);

                _fur.m_PositionWS.Add(position);
                _fur.m_RotationWS.Add(rotation);
                _fur.m_ScaleWS.Add(scaleR);
                _fur.m_Normal.Add(normalRor);
                _fur.m_UVs.Add(new Vector4(posOs_X, posOs_Z));

                // noiseUVs.Add(new Vector4(posOs_X,posOs_Z,normalRor.normalized.x,normalRor.normalized.y));
            }

            FurList.Add(_fur);

        }
    }

    public void UpdateList(InstancedFurData furData)
    {
       
        List<SingleFur> tempFurs = new List<SingleFur>();
        FurList = furData.allFurs;
        for (int index = 0; index < m_InstancedFurs.Count; index++)
        {
            InstancedFurComponent instancedFur = m_InstancedFurs[index];
            if (instancedFur.needRefresh||instancedFur.index==-1)
            {
                SingleFur _fur = new SingleFur();

 
                Transform furTrans = instancedFur.transform;
                var mesh = furTrans.GetComponent<MeshFilter>().sharedMesh;
                _fur.m_PositionWS = new List<Vector3>();
                _fur.m_RotationWS = new List<Quaternion>();
                _fur.m_ScaleWS = new List<Vector3>();
                _fur.m_UVs = new List<Vector2>();
                _fur.m_Normal = new List<Vector3>();
                
                // _fur.startID = positionWS.Count;
                _fur.position = furTrans.position;
                _fur.transform = furTrans;

                // _fur.bounds = mesh.bounds;
                var RotationRange = instancedFur.rotationRange;
                var ScaleRange = instancedFur.scaleRange;
                var Offset = instancedFur.offset;
                var scale = instancedFur.scale == Vector3.zero ? Vector3.one : instancedFur.scale;
                int vertexCount = mesh.vertexCount;
                var vertexColorArray = mesh.colors;
                var transRor = furTrans.rotation.normalized;

                minX = float.MaxValue;
                minZ = float.MaxValue;
                maxX = float.MinValue;
                maxZ = float.MinValue;
                // float sizeX =  mesh.bounds.extents.x;
                // float sizeZ =  mesh.bounds.extents.z;
                for (int i = 0; i < vertexCount; i++)
                {
                    Vector3 target = mesh.vertices[i];
                    minX = Mathf.Min(target.x, minX);
                    minZ = Mathf.Min(target.z, minZ);
                    maxX = Mathf.Max(target.x, maxX);
                    maxZ = Mathf.Max(target.z, maxZ);
                }

               
                for (int i = 0; i < vertexCount; i++)
                {
                    float posOs_X = Mathf.Abs(mesh.vertices[i].x - minX) / (maxX - minX);
                    float posOs_Z = Mathf.Abs(mesh.vertices[i].z - minZ) / (maxZ - minZ);

                    //Postion
                    var localPosition = new Vector3(mesh.vertices[i].x * furTrans.lossyScale.x,
                                            (mesh.vertices[i].y) * furTrans.lossyScale.y,
                                            mesh.vertices[i].z * furTrans.lossyScale.z) +
                                        mesh.normals[i] * Offset;

                    var Pos = quat_rot(new Vector4(transRor.x, transRor.y, transRor.z, transRor.w), localPosition);
                    Vector3 position = Pos + furTrans.position;


                    //Rotation
                    var normalRor = quat_rot(new Vector4(transRor.x, transRor.y, transRor.z, transRor.w),
                        mesh.normals[i]);

                    var ror = Quaternion.FromToRotation(new Vector3(0, 1, 0), normalRor.normalized);
                    var randomRor = Quaternion.Euler(0, Random.Range(-RotationRange, RotationRange), 0);
                    Quaternion rotation = ror * randomRor;
                    float vetexColor = ScaleRange;

                    if (vertexColorArray.Length > 0)
                        vetexColor = vertexColorArray[i].r * ScaleRange + 0.3f;
                    //Scale
                    Vector3 scaleR = new Vector3(scale.x * vetexColor, scale.y * vetexColor, scale.z * vetexColor);
                    
                    _fur.m_PositionWS.Add(position);
                    _fur.m_RotationWS.Add(rotation);
                    _fur.m_ScaleWS.Add(scaleR);
                    _fur.m_Normal.Add(normalRor);
                    _fur.m_UVs.Add(new Vector4(posOs_X, posOs_Z));

                    // noiseUVs.Add(new Vector4(posOs_X,posOs_Z,normalRor.normalized.x,normalRor.normalized.y));
                }
                instancedFur.index = index;
                tempFurs.Add(_fur);
                instancedFur.index = index;
                instancedFur.needRefresh = false;
            }
            else
            {
                var _fur = FurList[instancedFur.index];
                tempFurs.Add(_fur);
                instancedFur.index = index;
            }
        }
        FurList.Clear();
        FurList.AddRange(tempFurs);

    }

    void Reset()
    {

        FurList.Clear();
    }
}