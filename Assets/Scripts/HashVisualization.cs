using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;

using static Unity.Mathematics.math;

public class HashVisualization : MonoBehaviour {

	[BurstCompile(FloatPrecision.Standard, FloatMode.Fast, CompileSynchronously = true)]
	struct HashJob : IJobFor {


		static int hashesId = Shader.PropertyToID("_Hashes"),
			configId = Shader.PropertyToID("_Config");

		[SerializeField]
		Mesh instanceMesh;

		[SerializeField]
		Material material;

		[SerializeField, Range(1, 512)]
		int resolution;

		NativeArray<uint> hashes;

		ComputeBuffer hashesBuffer;

		MaterialPropertyBlock propertyBlock;
		
		public void Execute(int i) {
			hashes[i] = (uint)i;
		}
		
		void OnEnable () {
			int length = resolution * resolution;
			hashes = new NativeArray<uint>(length, Allocator.Persistent);
			hashesBuffer = new ComputeBuffer(length, 4);

			new HashJob {
				hashes = hashes
			}.ScheduleParallel(hashes.Length, resolution, default).Complete();

			hashesBuffer.SetData(hashes);

			propertyBlock ??= new MaterialPropertyBlock();
			propertyBlock.SetBuffer(hashesId, hashesBuffer);
			propertyBlock.SetVector(configId, new Vector4(resolution, 1f / resolution));
		}
	}
}