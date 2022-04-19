Shader "DeferedRP/LightPass"
{
    Properties
    {
        _MainTex("Texture",2D) = "white"{}
    }
    SubShader
    {
        Cull Off ZWrite On ZTest Always
        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "BRDF.cginc"
            #include "Random.cginc"
            #include "GlobalUniform.cginc"
            #include "Shadow.cginc"



            struct appdata
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float2 uv:TEXCOORD0;
                float4 vertex:SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }


            fixed4 frag(v2f i,out float DepthOut : SV_Depth): SV_Target
            {
                float2 uv = i.uv;
             
                // 从 Gbuffer 解码数据
                float4 GT2 = tex2D(_GT2, uv);
                float4 GT3 = tex2D(_GT3, uv);

                float3 albedo = tex2D(_GT0, uv).rgb;
                float3 normal = tex2D(_GT1, uv).rgb * 2 - 1;
                float2 motionVec = GT2.rg;
                float roughness = GT2.b;
                float metallic = GT2.a;
                float3 emission = GT3.rgb;
                float occlusion = GT3.a;

                //还原屏幕上每个点的位置信息，根据MatrixVPInv计算得到
                float d = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, uv));
                float d_lin = Linear01Depth(d);

                DepthOut = d;

                float4 ndcPos = float4(uv*2-1, d, 1);
                float4 worldPos = mul(_vpMatrixInv, ndcPos);
                worldPos /= worldPos.w;
  
                float3 N = normalize(normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
                float3 radiance = _LightColor0.rgb;

                float3 color = float3(0.0,0.0,0.0);


                //CSM TEST
                // if(d_lin<_Split0) 
                //     {
                //          color = float3(0.2,0,0);
                //     }
                // else if(d_lin<_Split0+_Split1) 
                //     {                   
                //          color = float3(0,1.0,0);
                //     }
                // else if(d_lin<_Split0+_Split1+_Split2) 
                //     {                  
                //          color = float3(0,0,1.0);
                //     }
                // else if(d_lin<_Split0+_Split1+_Split2+_Split3)
                //     {       
                //          color = float3(0.0,0,0);
                //     }

                float ShadowStrength = tex2D(_ShadowStrength,uv); 


                // 计算光照
                float3 Direct = PBR(N, V, L, albedo, radiance, roughness, metallic);

                float3 ambient = IBL(N, V, albedo,roughness,metallic,_DiffuseIBL,_SpecularIBL,_BrdfIBL );
                
                color += Direct * ShadowStrength;
                color += ambient * occlusion;
                color += emission;

                // //检测点在半影区域内
                // if(ShadowStrength > 0 && ShadowStrength < 1 )
                // {
                //     return float4(1.0,0,0,0);
                // }

                // #if UNITY_UV_STARTS_AT_TOP
                //     return float4(0.0,0.0,0.0,1.0);
                // #endif

                return float4(color, 1);
            }
            ENDCG
        }
    }
}