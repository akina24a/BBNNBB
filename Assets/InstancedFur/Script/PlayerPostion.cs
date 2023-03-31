using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerPostion : MonoBehaviour
{
    private Vector3 playerPos;
    void Update()
    {
        playerPos = transform.position;
        Shader.SetGlobalVector("_PlayerPos" , playerPos);
    }
}
