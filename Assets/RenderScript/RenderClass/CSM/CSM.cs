using System.Collections;
using System.Collections.Generic;
using UnityEngine;

struct MainCameraSettings
{
    public Vector3 Position;
    public Quaternion Rotation;
    public float NearClipPlane;
    public float FarClipPlane;
    public float Aspect;
}

public class CSM
{
    MainCameraSettings settings;

    public float[] Splts = { 0.15f, 0.20f, 0.35f, 0.55f };
    public float[] OrthoWidths = new float[4];

    //������Ľ�ƽ��Զƽ��
    Vector3[] FarCorners = new Vector3[4];
    Vector3[] NearCorners = new Vector3[4];


    Vector3[] F0_Near = new Vector3[4] , F0_Far = new Vector3[4];
    Vector3[] F1_Near = new Vector3[4] , F1_Far = new Vector3[4];
    Vector3[] F2_Near = new Vector3[4] , F2_Far = new Vector3[4];
    Vector3[] F3_Near = new Vector3[4] , F3_Far = new Vector3[4];

    Vector3[] box0, box1, box2, box3;

    Vector3 MatTransform(Matrix4x4 Mat,Vector3 V,float w)
    {
        Vector4 V4 = new Vector4(V.x,V.y,V.z,w);
        V4 = Mat * V4;
        return new Vector3(V4.x, V4.y, V4.z);
    }

    //�����ε�4+4������ͨ����ת����ķ�ʽת�Ƶ���Դ����
    //���������С������Ͱ�Χ�е�8������浽Points����
    Vector3[] LightSpaceAABB(Vector3[] NearCorners , Vector3[] FarCorners,Vector3 LightDir)
    {
        //World to Camera Inv
        Matrix4x4 ToShadowViewInv = Matrix4x4.LookAt(Vector3.zero, LightDir, Vector3.up);

        //��Χ��Ӧ���ͷ����һ����ת
        Matrix4x4 ToShadowView = ToShadowViewInv.inverse;

        //��׶�嶥��ת���Դ����
        for(int i = 0; i < 4; i++)
        {
            FarCorners[i] = MatTransform(ToShadowView, FarCorners[i],1.0f);
            NearCorners[i] = MatTransform(ToShadowView, NearCorners[i], 1.0f);
        }

        float[] x = new float[8];
        float[] y = new float[8];
        float[] z = new float[8];

        for (int i = 0; i < 4; i++)
        {
            x[i] = NearCorners[i].x; 
            x[i + 4] = FarCorners[i].x;

            y[i] = NearCorners[i].y; 
            y[i + 4] = FarCorners[i].y;

            z[i] = NearCorners[i].z; 
            z[i + 4] = FarCorners[i].z;
        }

        //ֱ�ӵõ����
        float xmin = Mathf.Min(x), xmax = Mathf.Max(x);
        float ymin = Mathf.Min(y), ymax = Mathf.Max(y);
        float zmin = Mathf.Min(z), zmax = Mathf.Max(z);

        Vector3[] points = 
            {
            new Vector3(xmin, ymin, zmin), new Vector3(xmin, ymin, zmax), new Vector3(xmin, ymax, zmin), new Vector3(xmin, ymax, zmax),
            new Vector3(xmax, ymin, zmin), new Vector3(xmax, ymin, zmax), new Vector3(xmax, ymax, zmin), new Vector3(xmax, ymax, zmax)
        };

        //�ӹ�ռ�ص���������
        for (int i = 0; i < 8; i++)
            points[i] = MatTransform(ToShadowViewInv, points[i], 1.0f);

        for (int i = 0; i < 4; i++)
        {
            FarCorners[i] = MatTransform(ToShadowViewInv, FarCorners[i], 1.0f);
            NearCorners[i] = MatTransform(ToShadowViewInv, NearCorners[i], 1.0f);
        }

        return points;
    }

    public void Update(Camera mainCamera,Vector3 LightDir)
    {
        //��ȡ���������׶��(��������)
        mainCamera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), mainCamera.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, FarCorners);
        mainCamera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), mainCamera.nearClipPlane, Camera.MonoOrStereoscopicEye.Mono, NearCorners);

        //��׶��ת������������ϵ
        for(int i = 0; i < 4; i++)
        {
            FarCorners[i] = mainCamera.transform.TransformVector(FarCorners[i]) + mainCamera.transform.position;
            NearCorners[i] = mainCamera.transform.TransformVector(NearCorners[i]) + mainCamera.transform.position;
        }

        //��ֵ����ÿ�����λ��
        for(int i = 0;i < 4; i++)
        {
            Vector3 dir = FarCorners[i] - NearCorners[i];

            F0_Near[i] = NearCorners[i];
            F0_Far[i] = F0_Near[i] + dir * Splts[0];

            F1_Near[i] = F0_Far[i];
            F1_Far[i] = F1_Near[i] + dir * Splts[1];

            F2_Near[i] = F1_Far[i];
            F2_Far[i] = F2_Near[i] + dir * Splts[2];

            F3_Near[i] = F2_Far[i];
            F3_Far[i] = F3_Near[i] + dir * Splts[3];
        }

        box0 = LightSpaceAABB(F0_Near, F0_Far, LightDir);
        box1 = LightSpaceAABB(F1_Near, F1_Far, LightDir);
        box2 = LightSpaceAABB(F2_Near, F2_Far, LightDir);
        box3 = LightSpaceAABB(F3_Near, F3_Far, LightDir);

        OrthoWidths[0] = Vector3.Magnitude(F0_Far[2] - F0_Near[0]);
        OrthoWidths[1] = Vector3.Magnitude(F1_Far[2] - F1_Near[0]);
        OrthoWidths[2] = Vector3.Magnitude(F2_Far[2] - F2_Near[0]);
        OrthoWidths[3] = Vector3.Magnitude(F3_Far[2] - F3_Near[0]);
    }

    void DrawFrustum(Vector3[] nearCorners, Vector3[] farCorners, Color color)
    {
        for (int i = 0; i < 4; i++)
            Debug.DrawLine(nearCorners[i], farCorners[i], color);

        Debug.DrawLine(farCorners[0], farCorners[1], color);
        Debug.DrawLine(farCorners[0], farCorners[3], color);
        Debug.DrawLine(farCorners[2], farCorners[1], color);
        Debug.DrawLine(farCorners[2], farCorners[3], color);
        Debug.DrawLine(nearCorners[0], nearCorners[1], color);
        Debug.DrawLine(nearCorners[0], nearCorners[3], color);
        Debug.DrawLine(nearCorners[2], nearCorners[1], color);
        Debug.DrawLine(nearCorners[2], nearCorners[3], color);
    }

    // ����Դ����� AABB ��Χ��
    void DrawAABB(Vector3[] points, Color color)
        {
            // ����
            Debug.DrawLine(points[0], points[1], color);
            Debug.DrawLine(points[0], points[2], color);
            Debug.DrawLine(points[0], points[4], color);

            Debug.DrawLine(points[6], points[2], color);
            Debug.DrawLine(points[6], points[7], color);
            Debug.DrawLine(points[6], points[4], color);

            Debug.DrawLine(points[5], points[1], color);
            Debug.DrawLine(points[5], points[7], color);
            Debug.DrawLine(points[5], points[4], color);

            Debug.DrawLine(points[3], points[1], color);
            Debug.DrawLine(points[3], points[2], color);
            Debug.DrawLine(points[3], points[7], color);
        }

    public void DebugDraw()
    {
        DrawFrustum(NearCorners, FarCorners, Color.white);
        DrawAABB(box0, Color.yellow);
        DrawAABB(box1, Color.magenta);
        DrawAABB(box2, Color.green);
        DrawAABB(box3, Color.cyan);
    }

    public void ConfigCameraToShadowSpace
        (
        ref Camera camera,
        Vector3 LightDir,
        int Level,
        float Distance,
        float Resolution)
    {
        var box = new Vector3[8];

        var F_Near = new Vector3[4];
        var F_Far = new Vector3[4];

        if (Level == 0)
        {
            box = box0;
            F_Near = F0_Near;
            F_Far = F0_Far;
        }

        if (Level == 1)
        {
            box = box1;
            F_Near = F1_Near;
            F_Far = F1_Far;
        }
        if (Level == 2)
        {
            box = box2;
            F_Near = F2_Near;
            F_Far = F2_Far;
        }
        if (Level == 3)
        {
            box = box3;
            F_Near = F3_Near;
            F_Far = F3_Far;
        }

        //����Box���е㣬��߱�
        Vector3 Center = (box[3] + box[4]) / 2;
        float W = Vector3.Magnitude(box[0] - box[4]);
        float H = Vector3.Magnitude(box[0] - box[2]);

        //�õ���Ӱͼ��ʵ�ʴ�С����׶��Χ�еĴ�С��
        float Len = Vector3.Magnitude(F_Far[2] -  F_Near[0]);
        float DisPerPix = Len / Resolution;

        Matrix4x4 ToShadowViewInv = Matrix4x4.LookAt(Vector3.zero, LightDir, Vector3.up);
        Matrix4x4 ToShadowView = ToShadowViewInv.inverse;

        //�������ת��ȡ��
        Center = MatTransform(ToShadowView, Center, 1.0f);
        for(int i = 0;i < 3 ;i++)
        {
            // Center[i]  / DisPerPix �൱�ڿ�������ĸ��ӣ����������Ͳ���ƫ����
            Center[i] = Mathf.Floor(Center[i] / DisPerPix) * DisPerPix;
        }

        Center = MatTransform(ToShadowViewInv,Center, 1.0f);

        // ����������õ���Ӧ����׶λ����ȥ
        camera.transform.rotation = Quaternion.LookRotation(LightDir);
        camera.transform.position = Center;
        camera.nearClipPlane = -Distance;
        camera.farClipPlane = Distance;
        camera.aspect = 1.0f;
        camera.orthographicSize = Len * 0.5f;
    }

    public void SaveMainCameraSettings(ref Camera camera)
    {
        settings.Position = camera.transform.position;
        settings.Rotation = camera.transform.rotation;
        settings.FarClipPlane = camera.farClipPlane;
        settings.NearClipPlane = camera.nearClipPlane;
        settings.Aspect = camera.aspect;
        camera.orthographic = true;
    }

    public void RevertMainCameraSettings(ref Camera camera)
    {
        camera.transform.position = settings.Position;
        camera.transform.rotation = settings.Rotation;
        camera.farClipPlane = settings.FarClipPlane;
        camera.nearClipPlane = settings.NearClipPlane;
        camera.aspect = settings.Aspect;
        camera.orthographic = false;
    }
}
