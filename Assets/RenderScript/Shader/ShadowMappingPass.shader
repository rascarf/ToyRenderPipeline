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
                
                // //Shadow Bias
                // float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // float bias = max(0.001 * (1.0 - dot(normal, lightDir)), 0.001);
                // if(dot(lightDir, normal) < 0.005) return 0; 

                // 随机旋转角度
                uint seed = RandomSeed(uv, float2(_ScreenWidth, _ScreenHeight));
                float2 uv_noi = uv * float2(_ScreenWidth, _ScreenHeight) / _NoiseTexResolution;
                float rotateAngle = rand(seed) * 2.0 * 3.1415926;
                rotateAngle = tex2D(_NoiseTex, uv_noi*0.5).r * 2.0 * 3.1415926;

                // if(_UsingShadowMask)
                // {
                //     float mask = tex2D(_ShadowMask,uv).r;

                //     if(0.0000005>mask) return 0;
                    
                //     if(mask>0.9999995) return 1;
                // }

                //根据深度决定使用哪一级阴影
                float Shadow = 1.0f;

                float3 color = float3(0,0,0);

                if(d_lin<_Split0) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias0;
                        // float Shadow0 = PCF3X3(worldPos,_ShadowTex0,_ShadowVpMatrix0,_ShadowMapResolution,0.001);
                        // Shadow *= ShadowMapPCSS(worldPosOffset,_ShadowTex0,_ShadowVpMatrix0,_OrthoWidth0,_OrthoDistance,_ShadowMapResolution,rotateAngle,_PcssSearchRadius0,_PcssFilterRadius0);
                        Shadow *= ESM(worldPosOffset,_ESM0,_ShadowVpMatrix0,_ESMConst);
                        
                    }
                else if(d_lin<_Split0+_Split1) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias1;
                        Shadow *= ESM(worldPosOffset,_ESM1,_ShadowVpMatrix1,_ESMConst);
                        // Shadow *= ShadowMapPCSS(worldPosOffset,_ShadowTex1,_ShadowVpMatrix1,_OrthoWidth1,_OrthoDistance,_ShadowMapResolution,rotateAngle,_PcssSearchRadius1,_PcssFilterRadius1);;
                    }
                else if(d_lin<_Split0+_Split1+_Split2) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias2;
                        Shadow *= ESM(worldPosOffset, _ESM2, _ShadowVpMatrix2,_ESMConst);

                    }
                else if(d_lin<_Split0+_Split1+_Split2+_Split3)
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias3;
                        Shadow *= ESM(worldPosOffset, _ESM3, _ShadowVpMatrix3,_ESMConst);
                    }

                return Shadow;
            }
            ENDCG
        }
        
    }
}