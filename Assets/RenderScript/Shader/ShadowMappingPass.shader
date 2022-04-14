Shader "DeferedRP/ShadowMappingPass"
{
    Properties
    {
        _MainTex("Texture",2D) = "white"{}
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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float3 normal = tex2D(_GT1, uv).rgb * 2 - 1;

                float d = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, uv));
                float d_lin = Linear01Depth(d);

                float4 ndcPos = float4(uv*2-1, d, 1);
                float4 worldPos = mul(_vpMatrixInv, ndcPos);
                worldPos /= worldPos.w;

                float4 worldPosOffset = worldPos;
                //Shadow Bias
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float bias = max(0.001 * (1.0 - dot(normal, lightDir)), 0.001);
                if(dot(lightDir, normal) < 0.005) return 0; //光线没有计算的必要

                // 随机旋转角度
                uint seed = RandomSeed(uv, float2(_ScreenWidth, _ScreenHeight));
                float2 uv_noi = uv * float2(_ScreenWidth, _ScreenHeight) / _NoiseTexResolution;
                float rotateAngle = rand(seed) * 2.0 * 3.1415926;
                rotateAngle = tex2D(_NoiseTex, uv_noi*0.5).r * 2.0 * 3.1415926;

                //根据深度决定使用哪一级阴影
                float Shadow = 1.0f;
                       
                // float Shadow1 = PCF3X3(worldPos,_ShadowTex1,_ShadowVpMatrix1,_ShadowMapResolution,0.001);
                // float Shadow1 = ShadowMapPCSS(worldOffset,_ShadowTex1,_ShadowVpMatrix1,_OrthoWidth1,_OrthoDistance,_ShadowMapResolution,rotateAngle,_PcssSearchRadius1,_PcssFilterRadius1);
                // float Shadow2 = ShadowMap01(worldOffset,_ShadowTex2,_ShadowVpMatrix2);
                // float Shadow3 = ShadowMap01(worldOffset,_ShadowTex3,_ShadowVpMatrix3);

                float3 color = float3(0,0,0);

                if(d_lin<_Split0) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias0;
                        // float Shadow0 = PCF3X3(worldPos,_ShadowTex0,_ShadowVpMatrix0,_ShadowMapResolution,0.001);
                        Shadow *= ShadowMapPCSS(worldPosOffset,_ShadowTex0,_ShadowVpMatrix0,_OrthoWidth0,_OrthoDistance,_ShadowMapResolution,rotateAngle,_PcssSearchRadius0,_PcssFilterRadius0);;
                        //  color = float3(0.2,0,0);
                    }
                else if(d_lin<_Split0+_Split1) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias1;
                        Shadow *= ShadowMapPCSS(worldPosOffset,_ShadowTex1,_ShadowVpMatrix1,_OrthoWidth1,_OrthoDistance,_ShadowMapResolution,rotateAngle,_PcssSearchRadius1,_PcssFilterRadius1);;
                        //  color = float3(0,1.0,0);
                    }
                else if(d_lin<_Split0+_Split1+_Split2) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias2;
                        Shadow *= ShadowMap01(worldPosOffset,_ShadowTex2,_ShadowVpMatrix2);
                        //  color = float3(0,0,1.0);

                    }
                else if(d_lin<_Split0+_Split1+_Split2+_Split3)
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias3;
                        Shadow *= ShadowMap01(worldPosOffset,_ShadowTex3,_ShadowVpMatrix3);
                        //  color = float3(0.0,0,0);
                    }

                return Shadow;
            }
            ENDCG
        }
        
    }
}