using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ShadowSettings
{
    public float ShadingPointNormalBias = 0.1f;
    public float DepthNormalBias = 0.005f;
    public float PcssSearchRadius = 1.0f;
    public float PcssFilterRadius = 7.0f;
}
