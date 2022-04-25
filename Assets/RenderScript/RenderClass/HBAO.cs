using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable]
public class HBAO
{
   public enum DIRECTION
    {
        DIRECT4,
        DIRECT6,
        DIRECT8,
    }

    public enum STEP
    {
        STEP4,
        STEP6,
        STEP8,
    }

    [SerializeField]
    DIRECTION mDirectionNumber = DIRECTION.DIRECT4;

    [SerializeField]
    STEP mStepNumber = STEP.STEP4;

    [SerializeField]
    [Range(0f, 3f)]
    float mAOStrength = 0.5f;

    [SerializeField]
    [Range(16, 256)]
    int mMaxRadiusPixel = 32; //最大像素检测半径

    [SerializeField]
    [Range(0.1f, 2.0f)]
    float mRadius = 0.5f; // 检测半径

    [SerializeField]
    [Range(0, 0.9f)]
    float mAngleBias = 0.1f; // 偏移角

    public void UpdateHBAOProperties(ScriptableRenderContext context, ref Camera sCamera)
    {
        var tanHalfFovY = Mathf.Tan(sCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);
        var tanHalfFovX = tanHalfFovY * ((float)sCamera.pixelWidth / sCamera.pixelHeight);

        //计算相机空间
        Shader.SetGlobalVector("_UV2View",new Vector4(2 * tanHalfFovX, 2 * tanHalfFovY, -tanHalfFovX, -tanHalfFovY));
        Shader.SetGlobalVector("_AOTexSize", new Vector4(1f / sCamera.pixelWidth, 1f / sCamera.pixelHeight, sCamera.pixelWidth, sCamera.pixelHeight));

        //当Z = 1的时候，半径为Radisu所对应的屏幕像素
        Shader.SetGlobalFloat("_RadiusPixel", 1024.0f * mRadius / tanHalfFovY / 2);
        Shader.SetGlobalFloat("_AORaidus", mRadius);
        Shader.SetGlobalFloat("_MaxRadiusPiexel", mMaxRadiusPixel);
        Shader.SetGlobalFloat("_AngleBias", mAngleBias);
        Shader.SetGlobalFloat("_AOStrength", mAOStrength);
    }
}
