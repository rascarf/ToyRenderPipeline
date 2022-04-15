Shader "DeferedRP/ShadowMaskPass"
{
    Properties
    {
        _MainTex("Texture",2D) = "White" {}
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "GlobalUniform.cginc"
            #include "UnityCG.cginc"
            #include "BRDF.cginc"
            #include "Shadow.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Random.cginc"            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }           

            float frag (v2f i) : SV_Target
            {
                float sum = 0;
                float2 uuvv = i.uv;

                for(float i=-1.5; i<=1.51; i++)
                {
                    for(float j=-1.5; j<=1.51; j++)
                    {
                        float2 offset = float2(i, j) / float2(_ScreenWidth, _ScreenWidth);
                        float2 uv = uuvv + offset;
                        float3 normal = tex2D(_GT1, uv).rgb * 2 - 1;
                        float d = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, uv));
                        float d_lin = Linear01Depth(d);

                        // 反投影重建世界坐标
                        float4 ndcPos = float4(uv*2-1, d, 1);
                        float4 worldPos = mul(_vpMatrixInv, ndcPos);
                        worldPos /= worldPos.w;

                        // 向着法线偏移采样点
                        float4 worldPosOffset = worldPos;
                        float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                        float NdotL = clamp(dot(lightDir, normal), 0, 1);

                        float shadow = 1.0;
                        float csmLevel = d_lin * (_Far - _Near) / 500.0;

                        if(csmLevel<_Split0) 
                        {
                            worldPosOffset.xyz += normal * _ShadingPointNormalBias0;
                            float bias = (1 * _OrthoWidth0 / _ShadowMapResolution) * _DepthNormalBias0;
                            shadow *= ShadowMap01(worldPosOffset, _ShadowTex0, _ShadowVpMatrix0);
                        }
                        else if(csmLevel<_Split0+_Split1)
                        {
                            worldPosOffset.xyz += normal * _ShadingPointNormalBias1;
                            float bias = (1 * _OrthoWidth1 / _ShadowMapResolution) * _DepthNormalBias1;
                            shadow *= ShadowMap01(worldPosOffset, _ShadowTex1, _ShadowVpMatrix1);
                        }
                        else if(csmLevel<_Split0+_Split1+_Split2) 
                        {   
                            worldPosOffset.xyz += normal * _ShadingPointNormalBias2;
                            float bias = (1 * _OrthoWidth2 / _ShadowMapResolution) * _DepthNormalBias2;
                            shadow *= ShadowMap01(worldPosOffset, _ShadowTex2, _ShadowVpMatrix2);
                        }
                        else if(csmLevel<_Split0+_Split1+_Split2+_Split3)
                        {
                            worldPosOffset.xyz += normal * _ShadingPointNormalBias3;
                            float bias = (1 * _OrthoWidth3 / _ShadowMapResolution) * _DepthNormalBias3;
                            shadow *= ShadowMap01(worldPosOffset, _ShadowTex3, _ShadowVpMatrix3);
                        }
                        sum += shadow;
                    }
                }

                return sum / 16;
            }
            ENDCG
        }
    }
}