using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/DeferedPipeline")]
public class DeferedPipelineAsset : RenderPipelineAsset
{
    public Cubemap DiffuseIBL;
    public Cubemap SpecularIBL;
    public Texture BrdfLut;
    public Texture BlueNoiseTex;

    public ComputeShader TestComputeShader;

    public bool Taa;

    [SerializeField] 
    public CSMSettings cmsSettings;

    protected override RenderPipeline CreatePipeline()
    {
        DeferedPipeline rp = new DeferedPipeline();

        rp.DiffuseIBL = DiffuseIBL; 
        rp.BrdfLut = BrdfLut; 
        rp.SpecularIBL = SpecularIBL;
        rp.CsmSettings = cmsSettings; 
        rp.BlueNoiseTex = BlueNoiseTex;
        rp.TestComputeShader = TestComputeShader;
        rp.bUseTaa = Taa;

        return rp;
    }
}
