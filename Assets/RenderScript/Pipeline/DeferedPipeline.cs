using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class DeferedPipeline : RenderPipeline
{
    public Cubemap DiffuseIBL;
    public Cubemap SpecularIBL;
    public Texture BrdfLut;

    public CSMSettings CsmSettings;
    public Texture BlueNoiseTex;
    public ComputeShader TestComputeShader;

    //GBuffers
    RenderTexture GDepth;
    RenderTexture[] GBuffer = new RenderTexture[4];
    RenderTargetIdentifier[] GBufferID = new RenderTargetIdentifier[4];

    RenderTexture[] ESMTextures = new RenderTexture[4];

    RenderTexture ShadowStrengthTex;
    RenderTexture ShadowMask;

    //Shadow
    CSM csm;
    RenderTexture[] ShadowTextures = new RenderTexture[4];
    public int ShadowMapResolution = 1024;

    public float OrthoDistance = 500.0f; //[-500,500]


    public DeferedPipeline()
    {
        GDepth = new RenderTexture(Screen.width,Screen.height,24,RenderTextureFormat.Depth,RenderTextureReadWrite.Linear);
        GBuffer[0] = new RenderTexture(Screen.width, Screen.height,0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        GBuffer[1] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB2101010, RenderTextureReadWrite.Linear);
        GBuffer[2] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        GBuffer[3] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

        ESMTextures[0] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        ESMTextures[1] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        ESMTextures[2] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        ESMTextures[3] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        ESMTextures[0].filterMode = FilterMode.Bilinear;
        ESMTextures[1].filterMode = FilterMode.Bilinear;
        ESMTextures[2].filterMode = FilterMode.Bilinear;
        ESMTextures[3].filterMode = FilterMode.Bilinear;

        for (int i =0; i<4;i++)
        {
            GBufferID[i] = GBuffer[i];
        }

        for(int i =0; i<4; i++)
        {
            ShadowTextures[i] = new RenderTexture(ShadowMapResolution, ShadowMapResolution, 24,RenderTextureFormat.Depth,RenderTextureReadWrite.Linear);
        }

        ShadowStrengthTex = new RenderTexture(Screen.width, Screen.height, 0,RenderTextureFormat.R8, RenderTextureReadWrite.Linear);

        ShadowMask = new RenderTexture(Screen.width / 4, Screen.height / 4, 0, RenderTextureFormat.R8, RenderTextureReadWrite.Linear);


        csm = new CSM();
    }
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        Camera camera = cameras[0];

        Matrix4x4 viewMatrix = camera.worldToCameraMatrix;
        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
        Matrix4x4 vpMatrix = projMatrix * viewMatrix;
        Matrix4x4 vpMatrixInv = vpMatrix.inverse;

        Shader.SetGlobalMatrix("_vpMatrix", vpMatrix);
        Shader.SetGlobalMatrix("_vpMatrixInv", vpMatrixInv);

        Shader.SetGlobalTexture("_DiffuseIBL", DiffuseIBL);
        Shader.SetGlobalTexture("_SpecularIBL", SpecularIBL);
        Shader.SetGlobalTexture("_BrdfIBL", BrdfLut);
        Shader.SetGlobalTexture("_GDepth", GDepth);
        Shader.SetGlobalTexture("_NoiseTex", BlueNoiseTex);
        Shader.SetGlobalTexture("_ShadowStrength", ShadowStrengthTex);
        Shader.SetGlobalTexture("_ShadowMask", ShadowMask);

        Shader.SetGlobalFloat("_Far", camera.farClipPlane);
        Shader.SetGlobalFloat("_Near", camera.nearClipPlane);
        Shader.SetGlobalFloat("_ScreenWidth", Screen.width);
        Shader.SetGlobalFloat("_ScreenHeight", Screen.height);
        Shader.SetGlobalFloat("_OrthoDistance", OrthoDistance);
        Shader.SetGlobalFloat("_ShadowMapResolution", ShadowMapResolution);
        Shader.SetGlobalFloat("_NoiseTexResolution", BlueNoiseTex.width);

        Shader.SetGlobalFloat("_ESMConst", 10.0f);

        for (int i = 0; i < 4; i++)
        {
            Shader.SetGlobalTexture("_GT" + i, GBuffer[i]);
        }



        DepthOnlyPass(context, camera);
        GBufferPass(context, camera);
        ShadowMappingPass(context, camera);
        LightPass(context, camera);
        SkyDomePass(context, camera);
    }

    void DepthOnlyPass(ScriptableRenderContext context, Camera Camera)
    {
        Light light = RenderSettings.sun;
        Vector3 LightDir = light.transform.rotation * Vector3.forward;

        for (int i = 0; i < 4; i++)
        {
            Shader.SetGlobalTexture("_ShadowTex" + i, ShadowTextures[i]);
            Shader.SetGlobalFloat("_Split" + i, csm.Splts[i]);
        }

        csm.Update(Camera, LightDir);
        CsmSettings.Set();

        csm.SaveMainCameraSettings(ref Camera);
        for (int Level = 0; Level < 4; Level++)
        {
            //相机矩阵要变换后再更新，这才是光矩阵
            csm.ConfigCameraToShadowSpace(ref Camera, LightDir, Level, OrthoDistance , ShadowMapResolution);

            Matrix4x4 V = Camera.worldToCameraMatrix;
            Matrix4x4 P = GL.GetGPUProjectionMatrix(Camera.projectionMatrix, false);
            Shader.SetGlobalMatrix("_ShadowVpMatrix" + Level, P * V);
            Shader.SetGlobalFloat("_OrthoWidth" + Level, csm.OrthoWidths[Level]);

            CommandBuffer cmd = new CommandBuffer();
            cmd.name = "ShadowMap" + Level;

            //绘制准备
            context.SetupCameraProperties(Camera);

            cmd.SetRenderTarget(ShadowTextures[Level]);
            cmd.ClearRenderTarget(true, true, Color.blue);

            context.ExecuteCommandBuffer(cmd);

            //剔除
            Camera.TryGetCullingParameters(out var cullingParameters);
            var cullingResults = context.Cull(ref cullingParameters);

            ShaderTagId shaderTagId = new ShaderTagId("depthonly");

            SortingSettings sortingSettings = new SortingSettings(Camera);
            DrawingSettings drawingSettings = new DrawingSettings(shaderTagId, sortingSettings);
            FilteringSettings filteringSettings = FilteringSettings.defaultValue;

            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

            context.Submit();
        }

        csm.RevertMainCameraSettings(ref Camera);
    }
    void GBufferPass(ScriptableRenderContext context, Camera Camera)
    {
        //为DrawRenderer准备三参数
        context.SetupCameraProperties(Camera);

        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "GBuffer";

        //直接绑定
        cmd.SetRenderTarget(GBufferID, GDepth); // 和DX有点像
        cmd.ClearRenderTarget(true, true, Color.blue);
        context.ExecuteCommandBuffer(cmd);

        //剔除
        Camera.TryGetCullingParameters(out var cullingParameters);
        var cullingResult = context.Cull(ref cullingParameters);

        //设置Shader
        ShaderTagId shaderTagId = new ShaderTagId("GBuffer");
        SortingSettings sortingSettings = new SortingSettings(Camera);

        //剩下俩参数
        DrawingSettings drawingSettings = new DrawingSettings(shaderTagId, sortingSettings);
        FilteringSettings filteringSettings = FilteringSettings.defaultValue;

        context.DrawRenderers(cullingResult, ref drawingSettings, ref filteringSettings);
    }
    void ShadowMappingPass(ScriptableRenderContext context, Camera Camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "ShadowMapPass";


        cmd.Blit(ShadowTextures[0], ESMTextures[0], new Material(Shader.Find("DeferedRP/ESMFilter")));
        cmd.Blit(ShadowTextures[1], ESMTextures[1], new Material(Shader.Find("DeferedRP/ESMFilter")));
        cmd.Blit(ShadowTextures[2], ESMTextures[2], new Material(Shader.Find("DeferedRP/ESMFilter")));
        cmd.Blit(ShadowTextures[3], ESMTextures[3], new Material(Shader.Find("DeferedRP/ESMFilter")));

        for (int i = 0; i < 4; i++)
        {
            Shader.SetGlobalTexture("_ESM" + i, ESMTextures[i]);
        }

        /*
        RenderTexture tempTex1 = RenderTexture.GetTemporary(Screen.width / 4, Screen.height / 4, 0, RenderTextureFormat.R8, RenderTextureReadWrite.Linear);
        RenderTexture tempTex2 = RenderTexture.GetTemporary(Screen.width / 4, Screen.height / 4, 0, RenderTextureFormat.R8, RenderTextureReadWrite.Linear);
        RenderTexture tempTex3 = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.R8, RenderTextureReadWrite.Linear);

        //如果需要用到Mask
        if (CsmSettings.UsingShadowMask)
        {
            //生成Mask
            cmd.Blit(GBufferID[0], tempTex1, new Material(Shader.Find("DeferedRP/ShadowMaskPass")));
            cmd.Blit(tempTex1, tempTex2, new Material(Shader.Find("DeferedRP/HorizontalBlur")));
            cmd.Blit(tempTex2, ShadowMask, new Material(Shader.Find("DeferedRP/VerticalBlur")));
        }

        cmd.Blit(GBufferID[0], tempTex3, new Material(Shader.Find("DeferedRP/ShadowMappingPass")));
        cmd.Blit(tempTex3, ShadowStrengthTex, new Material(Shader.Find("DeferedRP/Blur")));


        RenderTexture.ReleaseTemporary(tempTex1);
        RenderTexture.ReleaseTemporary(tempTex2);
        RenderTexture.ReleaseTemporary(tempTex3);*/

        // cmd.Blit(GBufferID[0], ESMShadowTextures, new Material(Shader.Find("DeferedRP/ESMOnlyDepth")));

        cmd.Blit(GBufferID[0], ShadowStrengthTex, new Material(Shader.Find("DeferedRP/ShadowMappingPass")));

        context.ExecuteCommandBuffer(cmd);
        context.Submit();
    }
    void LightPass(ScriptableRenderContext context , Camera Camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "LightPass";

        Material mat = new Material(Shader.Find("DeferedRP/LightPass"));

        //拿到GbufferID0的内容，输出到Camera上
        cmd.Blit(GBufferID[0],BuiltinRenderTextureType.CameraTarget,mat);

        context.ExecuteCommandBuffer(cmd);

        context.Submit();
    }
    void SkyDomePass(ScriptableRenderContext context, Camera Camera)
    {
        context.DrawSkybox(Camera);
        if (Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(Camera, GizmoSubset.PreImageEffects);
            context.DrawGizmos(Camera, GizmoSubset.PostImageEffects);
        }

        context.Submit();
    }
}
