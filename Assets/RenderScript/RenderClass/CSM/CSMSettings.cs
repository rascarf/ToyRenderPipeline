using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[System.Serializable]
public class CSMSettings
{
    public float MaxDistance = 200;
    public bool UsingShadowMask = false;

    public ShadowSettings Level0;
    public ShadowSettings Level1;
    public ShadowSettings Level2;
    public ShadowSettings Level3;

    public void Set()
    {
        ShadowSettings[] Levels = { Level0, Level1, Level2, Level3 };
        for(int i = 0; i < Levels.Length; i++)
        {
            Shader.SetGlobalFloat("_ShadingPointNormalBias" + i, Levels[i].ShadingPointNormalBias);
            Shader.SetGlobalFloat("_DepthNormalBias" + i, Levels[i].DepthNormalBias);
            Shader.SetGlobalFloat("_PcssSearchRadius" + i, Levels[i].PcssSearchRadius);
            Shader.SetGlobalFloat("_PcssFilterRadius" + i, Levels[i].PcssFilterRadius);
        }

        Shader.SetGlobalFloat("_UsingShadowMask", UsingShadowMask ? 1.0f : 0.0f);
        Shader.SetGlobalFloat("_CsmMaxDistance", MaxDistance);
    }

}
