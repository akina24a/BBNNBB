using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;


// [ExecuteAlways]
public class InstancedFurComponent : MonoBehaviour
{
    private int population;
    public float rotationRange= 30f;
    public float scaleRange =1f;
    public float offset =1f;
    // public bool useNoiseTex =true;
    public Vector3 scale = new Vector3(1,1,1);
    public bool needRefresh  =false;
    // [HideInInspector]
    // public int startId=-1;
    // [HideInInspector]
    // public int endId=-1;

    [HideInInspector] 
    public int index = -1;
    void Awake()
    {

        // InstancedFurManager.Instance.Register(this);
        // Debug.Log("re");
    }

    void OnDestroy()
    {
        // InstancedFurManager.Instance.Unregister(this);
        // Debug.Log("Unre");
    }

    
}