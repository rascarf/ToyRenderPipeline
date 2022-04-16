Shader "DeferedRP/VSMShadowMappingPass"
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
                
                //根据深度决定使用哪一级阴影
                float Shadow = 1.0f;

                float3 color = float3(0,0,0);

                if(d_lin<_Split0) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias0;
                        Shadow *= VSM(worldPosOffset,_ESM0,_ShadowVpMatrix0);                       
                    }
                else if(d_lin<_Split0+_Split1) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias1;
                        Shadow *= VSM(worldPosOffset,_ESM1,_ShadowVpMatrix1);
                    }
                else if(d_lin<_Split0+_Split1+_Split2) 
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias2;
                        Shadow *= VSM(worldPosOffset,_ESM2,_ShadowVpMatrix2);

                    }
                else if(d_lin<_Split0+_Split1+_Split2+_Split3)
                    {
                        worldPosOffset.xyz += normal * _ShadingPointNormalBias3;
                        Shadow *= VSM(worldPosOffset,_ESM3,_ShadowVpMatrix3);
                    }

                return Shadow;
            }
            ENDCG
        }
        
    }
}