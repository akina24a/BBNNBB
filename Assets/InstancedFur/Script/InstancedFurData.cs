using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "InstancedFurData", menuName = "InstancedFurData")]
public class InstancedFurData : ScriptableObject
{

    public List<SingleFur> allFurs;


    public void SaveData(bool refreshAll = false)
    {

        var allComponents = GameObject.FindObjectsOfType<InstancedFurComponent>();
        InstancedFurManager.Instance.Clear();
        for (int i = 0; i < allComponents.Length; i++)
        {
            
            InstancedFurManager.Instance.Register(allComponents[i]);
        }
        if(refreshAll)
            InstancedFurManager.Instance.UpdateAllList();
        else
            InstancedFurManager.Instance.UpdateList(this);
        allFurs = InstancedFurManager.Instance.GetFurList();

    }
}
