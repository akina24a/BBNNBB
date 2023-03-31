using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FurBendingRTPrePass : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        static readonly int _FurBendingRT_pid = Shader.PropertyToID("_FurBendingRT");
        static readonly RenderTargetIdentifier _FurBendingRT_rti = new RenderTargetIdentifier(_FurBendingRT_pid);
        ShaderTagId FurBending_stid = new ShaderTagId("FurBending");

 
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            cmd.GetTemporaryRT(_FurBendingRT_pid, new RenderTextureDescriptor(512, 512, RenderTextureFormat.R8,0));
            ConfigureTarget(_FurBendingRT_rti);
            ConfigureClear(ClearFlag.All, Color.black);
        }

       
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            CommandBuffer cmd = CommandBufferPool.Get("FurBendingRT");

            // Matrix4x4 viewMatrix = Matrix4x4.TRS(new Vector3(renderingData.cameraData.camera.transform.position.x,5,renderingData.cameraData.camera.transform.position.z) ,Quaternion.LookRotation(-Vector3.up), new Vector3(1,1,-1)).inverse;
            //
            // float sizeX =50;
            // float sizeZ =50;
            // Matrix4x4 projectionMatrix = Matrix4x4.Ortho(-sizeX,sizeX, -sizeZ, sizeZ, 0.5f, 20f);
            // context.ExecuteCommandBuffer(cmd);
            cmd.SetGlobalFloat("_FURBENDING", 1);
            var drawSetting = CreateDrawingSettings(FurBending_stid, ref renderingData, SortingCriteria.CommonTransparent);
            var filterSetting = new FilteringSettings(RenderQueueRange.all); 
            context.DrawRenderers(renderingData.cullResults, ref drawSetting, ref filterSetting);

            // cmd.Clear();
            // cmd.SetViewProjectionMatrices(renderingData.cameraData.camera.worldToCameraMatrix, renderingData.cameraData.camera.projectionMatrix);

            cmd.SetGlobalTexture(_FurBendingRT_pid, new RenderTargetIdentifier(_FurBendingRT_pid));

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.SetGlobalFloat("_FURBENDING", 0);
            cmd.ReleaseTemporaryRT(_FurBendingRT_pid);
        }
    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses; 
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


