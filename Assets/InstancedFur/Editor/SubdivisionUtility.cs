using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
// using Random = UnityEngine.Random;

public static class  SubdivisionUtility 
{
    public static MeshFilter CheckMeshFilter(GameObject obj)
    {
        if (obj == null) throw new System.NullReferenceException("No GameObject specified");

        var mf = obj.GetComponent<MeshFilter>();
        if (mf == null) throw new System.Exception("No MeshFilter found for " + obj.name);

        if (mf.sharedMesh == null) throw new System.Exception("No mesh set to " + obj.name);

        return mf;
    }
    
    public static Mesh Subdivide(GameObject obj, float iterations) {
        if (iterations <= 0) return null;

        MeshFilter mf = CheckMeshFilter(obj);

        Mesh originalMesh = mf.sharedMesh;

        //Mesh mesh = Object.Instantiate<Mesh>(originalMesh); // no need to copy: Subdivide doesn't change the Mesh
        mf.sharedMesh = Subdivide(originalMesh, iterations);
        return  Subdivide(originalMesh, iterations);
        
    }
    
    static private double random()
    {
        var seed = Guid.NewGuid().GetHashCode();  
        System.Random r = new System.Random(seed);
        int i = r.Next(0, 100000);
        return (double)i / 100000;
    }

    static float RandomRange(float min, float max,int seed)
    {
        System.Random r = new System.Random(seed);
        var random = r.NextDouble();
        return (float) (random * (max - min) + min);
    }    
    
    static Mesh CloneMesh(Mesh originalMesh)
    {
        Mesh newMesh = new Mesh();

        newMesh.vertices = originalMesh.vertices;
        newMesh.normals = originalMesh.normals;
        newMesh.tangents = originalMesh.tangents;
        newMesh.uv = originalMesh.uv;
        if(originalMesh.uv2!=null&& originalMesh.uv2.Length>0)
            newMesh.uv2 = originalMesh.uv2;
        if (originalMesh.uv3 != null && originalMesh.uv3.Length > 0)
            newMesh.uv3 = originalMesh.uv3;
        if (originalMesh.uv4 != null && originalMesh.uv4.Length > 0)
            newMesh.uv4 = originalMesh.uv4;
        if (originalMesh.colors32 != null && originalMesh.colors32.Length > 0)
            newMesh.colors32 = originalMesh.colors32;
    
        newMesh.triangles = originalMesh.triangles;
        newMesh.bindposes = originalMesh.bindposes;
        newMesh.boneWeights = originalMesh.boneWeights;

        Debug.Log(newMesh.indexFormat);


        newMesh.subMeshCount = originalMesh.subMeshCount;
        if (newMesh.subMeshCount > 1)
        {
            for (var i = 0; i < newMesh.subMeshCount; i++)
            {
                newMesh.SetTriangles(originalMesh.GetTriangles(i), i);
            }
        }

        return newMesh;
    }
    
    static Mesh Subdivide(Mesh mesh,float iterations)  
    {  
        if (mesh.vertexCount >= 18432)  
        {  
            Debug.Log("Too Many");  
            return mesh;  
        }  
        var origVertices = mesh.vertices;  
        var origNormals = mesh.normals;  
        var origTrangles = mesh.triangles;  
        
        Mesh copyMesh = CloneMesh(mesh);
        copyMesh.name = mesh.name + "_new";
     
        Dictionary<Vector3, int> verticesResultDic = new Dictionary<Vector3, int>();  
        Dictionary<Vector3, int> normalsResultDic = new Dictionary<Vector3, int>();  
        List<int> tranglesResultList = new List<int>();  
        //计算三角面的个数  
        int k = origTrangles.Length / 3;  
        int vertexIndex = 0;  
        int normalIndex = 0;  
        for (int i = 0; i < k; i++)
        {
            var range=  RandomRange(0, 1,(int)Mathf.Floor(i/3));
            // Debug.Log(aa);
            // continue;
            Vector3[] trangle = new Vector3[3] { origVertices[origTrangles[i * 3]], origVertices[origTrangles[i * 3 + 1]], origVertices[origTrangles[i * 3 + 2]] };  
            Vector3[] normal = new Vector3[3] { origNormals[origTrangles[i * 3]], origNormals[origTrangles[i * 3 + 1]], origNormals[origTrangles[i * 3 + 2]] };  
            if (range > iterations)
            {
                if (AddVertices(verticesResultDic, trangle[0], vertexIndex)) vertexIndex++;  
                if (AddVertices(verticesResultDic, trangle[1], vertexIndex)) vertexIndex++;  
                if (AddVertices(verticesResultDic, trangle[2], vertexIndex)) vertexIndex++; 
                
                if (AddNormals(normalsResultDic, normal[0], normalIndex)) normalIndex++;  
                if (AddNormals(normalsResultDic, normal[1], normalIndex)) normalIndex++;  
                if (AddNormals(normalsResultDic, normal[2], normalIndex)) normalIndex++;  
                
                tranglesResultList.Add(verticesResultDic[trangle[0]]);
                tranglesResultList.Add(verticesResultDic[trangle[1]]);
                tranglesResultList.Add(verticesResultDic[trangle[2]]);  
                continue;
            }
               
            //取出一个三角面（的顶点）  
           
            //通过取三条边的中心点  
            //原来三个顶点，变成六个顶点  
            Vector3[] result = new Vector3[6];  
            Vector3 v01 = (trangle[0] + trangle[1]) * 0.5f;  
            Vector3 v12 = (trangle[1] + trangle[2]) * 0.5f;  
            Vector3 v02 = (trangle[0] + trangle[2]) * 0.5f;  
            if (AddVertices(verticesResultDic, trangle[0], vertexIndex)) vertexIndex++;  
            if (AddVertices(verticesResultDic, trangle[1], vertexIndex)) vertexIndex++;  
            if (AddVertices(verticesResultDic, trangle[2], vertexIndex)) vertexIndex++;  
            if (AddVertices(verticesResultDic, v01, vertexIndex)) vertexIndex++;  
            if (AddVertices(verticesResultDic, v12, vertexIndex)) vertexIndex++;  
            if (AddVertices(verticesResultDic, v02, vertexIndex)) vertexIndex++; 
            
            Vector3 n01 = (normal[0] + normal[1]) * 0.5f;  
            Vector3 n12 = (normal[1] + normal[2]) * 0.5f;  
            Vector3 n02 = (normal[0] + normal[2]) * 0.5f;  
            if (AddNormals(normalsResultDic, normal[0], normalIndex)) normalIndex++;  
            if (AddNormals(normalsResultDic, normal[1], normalIndex)) normalIndex++;  
            if (AddNormals(normalsResultDic, normal[2], normalIndex)) normalIndex++;  
            if (AddNormals(normalsResultDic, n01, normalIndex)) normalIndex++;  
            if (AddNormals(normalsResultDic, n12, normalIndex)) normalIndex++;  
            if (AddNormals(normalsResultDic, n02, normalIndex)) normalIndex++; 
            
            // 将原三角面分成新的四个三角面  
            // 注意左手法则，逆时针顺序  
            //三角形数组存储的是顶点在顶点数组中的序号  
            tranglesResultList.Add(verticesResultDic[trangle[0]]);  
            tranglesResultList.Add(verticesResultDic[v01]);  
            tranglesResultList.Add(verticesResultDic[v02]);  
            tranglesResultList.Add(verticesResultDic[v01]);  
            tranglesResultList.Add(verticesResultDic[trangle[1]]);  
            tranglesResultList.Add(verticesResultDic[v12]);  
            tranglesResultList.Add(verticesResultDic[trangle[2]]);  
            tranglesResultList.Add(verticesResultDic[v02]);  
            tranglesResultList.Add(verticesResultDic[v12]);  
            tranglesResultList.Add(verticesResultDic[v02]);  
            tranglesResultList.Add(verticesResultDic[v01]);  
            tranglesResultList.Add(verticesResultDic[v12]);  
        }

        // return mesh;
        copyMesh.vertices = GetReusltVertices(verticesResultDic);  
        copyMesh.triangles = tranglesResultList.ToArray();  
        copyMesh.RecalculateBounds();  
            //由于normal没有增加，导致表面看起来不平滑(如果要重新计算normals参考顶点的计算)  
            copyMesh.normals = GetReusltNormals(normalsResultDic);  
            copyMesh.RecalculateNormals();
            return copyMesh;
    }
    static bool AddVertices(Dictionary<Vector3, int> verticesResultDic, Vector3 vertice, int index)  
    {
        if (verticesResultDic.ContainsValue(index) || verticesResultDic.ContainsKey(vertice))  
            return false;  
        verticesResultDic.Add(vertice, index);  
        return true;  
    }
    static bool AddNormals(Dictionary<Vector3, int> verticesResultDic, Vector3 vertice, int index)  
    {
        if (verticesResultDic.ContainsValue(index) || verticesResultDic.ContainsKey(vertice))  
            return false;  
        verticesResultDic.Add(vertice, index);  
        return true;  
    }
    static Vector3[] GetReusltNormals( Dictionary< Vector3,int> verticesResultDic)  
    {  
        int length = verticesResultDic.Keys.Count;  
        Vector3[] result = new Vector3[length];  
        List<Vector3> temp = new List<Vector3>(verticesResultDic.Keys);  
        for (int i = 0; i < length; i++)  
        {
            result[i] = temp[i];
  
        }  
        return result;  
    }
    
    static Vector3[] GetReusltVertices( Dictionary< Vector3,int> verticesResultDic)  
    {  
        int length = verticesResultDic.Keys.Count;  
        Vector3[] result = new Vector3[length];  
        List<Vector3> temp = new List<Vector3>(verticesResultDic.Keys);  
        for (int i = 0; i < length; i++)  
        {
            result[i] = temp[i];
  
            }  
        return result;  
    }
}
