using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class TAAPass
{
    private RenderTexture[] m_HistoryTextures = new RenderTexture[2];

    private Vector2[] HaltonSequence = new Vector2[]
    {
        new Vector2(0.5f, 1.0f / 3),
        new Vector2(0.25f, 2.0f / 3),
        new Vector2(0.75f, 1.0f / 9),
        new Vector2(0.125f, 4.0f / 9),
        new Vector2(0.625f, 7.0f / 9),
        new Vector2(0.375f, 2.0f / 9),
        new Vector2(0.875f, 5.0f / 9),
        new Vector2(0.0625f, 8.0f / 9),
    };

    private bool m_ResetHistory = true;

    private int FrameIndex = 0;

    private Vector2 _Jitter;

    public Matrix4x4 OriginalVPMatrix;
    public Matrix4x4 JitterVPMatrix;

    public void PreCull(ScriptableRenderContext context, ref Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();

        OriginalVPMatrix = camera.projectionMatrix;
        JitterVPMatrix = OriginalVPMatrix;

        camera.nonJitteredProjectionMatrix = OriginalVPMatrix;

        FrameIndex++;

        var Index = FrameIndex % 8;

        _Jitter = new Vector2(
                    (HaltonSequence[Index].x - 0.5f) / 1024.0f * 2,
                    (HaltonSequence[Index].y - 0.5f) / 1024.0f * 2
                ); // 直接算uv下的偏移值

        JitterVPMatrix.m02 += _Jitter.x;
        JitterVPMatrix.m12 += _Jitter.y;

        camera.projectionMatrix = JitterVPMatrix;
    }
    public void OnRender(ref RenderTexture Source, BuiltinRenderTextureType Dest, ScriptableRenderContext context)
    {
        var HistoryRead = m_HistoryTextures[FrameIndex % 2];
        if(HistoryRead == null || HistoryRead.width != 1024 || HistoryRead.height != 1024)
        {
            if(HistoryRead != null) HistoryRead.Release();

            HistoryRead = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);
            HistoryRead.name = "HistoryRead";
            m_HistoryTextures[FrameIndex % 2] = HistoryRead;
            HistoryRead.filterMode = FilterMode.Bilinear;
            m_ResetHistory = true;
        }

        var HistoryWrite = m_HistoryTextures[(FrameIndex + 1) % 2];
        if(HistoryWrite == null || HistoryWrite.width != 1024 || HistoryWrite.height != 1024)
        {
            if (HistoryWrite != null) HistoryWrite.Release();

            HistoryWrite = RenderTexture.GetTemporary(1024, 1024, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            HistoryWrite.filterMode = FilterMode.Bilinear;
            HistoryWrite.name = "HistoryWrite";
            m_HistoryTextures[(FrameIndex+1) % 2] = HistoryWrite;
            m_ResetHistory = true;
            
        }

        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "TaaPass";

        Shader.SetGlobalVector("_Jitter", _Jitter);
        Shader.SetGlobalTexture("_HistoryTex", HistoryRead);
        Shader.SetGlobalTexture("_OnlyTAA", Source);
        Shader.SetGlobalInt("_IgnoreHistory", m_ResetHistory ? 1 : 0);

        Material TaaMaterial = new Material(Shader.Find("DeferedRP/TAA"));

        cmd.Blit(Source, HistoryWrite, TaaMaterial);

        cmd.Blit(HistoryWrite, Dest);

        m_ResetHistory = false;

        context.ExecuteCommandBuffer(cmd);

        context.Submit();
    }

    public void OnPostRender(ScriptableRenderContext context,ref Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();    
        context.ExecuteCommandBuffer(cmd);
        context.Submit();

        camera.projectionMatrix = OriginalVPMatrix;
    }


}

