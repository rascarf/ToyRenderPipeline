Shader "DeferedRP/TAA"
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

            sampler2D _HistoryTex; 
            sampler2D _GT2;
            sampler2D _LightOut;
            sampler2D _GDepth;
            int _IgnoreHistory;
            float2 _Jitter;

            float fstep(float a,float b)
            {
                return a > b ? 1 : 0;
            }

            float3 RGBToYCoCg( float3 RGB )
                {
	                float Y  = dot( RGB, float3(  1, 2,  1 ) );
	                float Co = dot( RGB, float3(  2, 0, -2 ) );
	                float Cg = dot( RGB, float3( -1, 2, -1 ) );
	                
	                float3 YCoCg = float3( Y, Co, Cg );
	                return YCoCg;
                }

                float3 YCoCgToRGB( float3 YCoCg )
                {
	                float Y  = YCoCg.x * 0.25;
	                float Co = YCoCg.y * 0.25;
	                float Cg = YCoCg.z * 0.25;

	                float R = Y + Co - Cg;
	                float G = Y + Cg;
	                float B = Y - Co - Cg;

	                float3 RGB = float3( R, G, B );
	                return RGB;
                }

                float3 ClipHistory(float3 History, float3 BoxMin, float3 BoxMax)
                {
                    float3 Filtered = (BoxMin + BoxMax) * 0.5f;
                    float3 RayOrigin = History;
                    float3 RayDir = Filtered - History;
                    RayDir = abs( RayDir ) < (1.0/65536.0) ? (1.0/65536.0) : RayDir;
                    float3 InvRayDir = rcp( RayDir );
                
                    float3 MinIntersect = (BoxMin - RayOrigin) * InvRayDir;
                    float3 MaxIntersect = (BoxMax - RayOrigin) * InvRayDir;
                    float3 EnterIntersect = min( MinIntersect, MaxIntersect );
                    float ClipBlend = max( EnterIntersect.x, max(EnterIntersect.y, EnterIntersect.z ));
                    ClipBlend = saturate(ClipBlend);
                    return lerp(History, Filtered, ClipBlend);
                }

            float2 GetClosetFragment(float2 uv)
            {
                float2 step = (1 / 1024.0,1 / 1024.0);

                float4 neighborhood = float4(
                    tex2D(_GDepth,uv - step).r,
                    tex2D(_GDepth,uv + float2(step.x,-step.y)).r,
                    tex2D(_GDepth,uv + float2(-step.x,step.y)).r,
                    tex2D(_GDepth,uv + step).r
                );

            #if defined(UNITY_REVERSED_Z)
                #define COMPARE_DEPTH(a, b) fstep(b, a)
            #else
                #define COMPARE_DEPTH(a, b) fstep(a, b)
            #endif

                float3 result = float3(0.0, 0.0, tex2D(_GDepth, uv).r);

                result = lerp(result, float3(-1.0, -1.0, neighborhood.x), fstep(result.z,neighborhood.x));
                result = lerp(result, float3( 1.0, -1.0, neighborhood.y), COMPARE_DEPTH(neighborhood.y, result.z));
                result = lerp(result, float3(-1.0,  1.0, neighborhood.z), COMPARE_DEPTH(neighborhood.z, result.z));
                result = lerp(result, float3( 1.0,  1.0, neighborhood.w), COMPARE_DEPTH(neighborhood.w, result.z));

                return (uv + result.xy * step);
            }

             static const int2 kOffsets3x3[9] =
                {
	                int2(-1, -1),
	                int2( 0, -1),
	                int2( 1, -1),
	                int2(-1,  0),
                    int2( 0,  0),
	                int2( 1,  0),
	                int2(-1,  1),
	                int2( 0,  1),
	                int2( 1,  1),
                };

            float4 frag(v2f i,float DepthOut : SV_Depth):SV_Target
            {
                float2 step = 1 / 1024.0;
                float2 uv = i.uv;
                float2 UnJitterUV =  i.uv - _Jitter; //这是Jitter的
                float4 Color = tex2D(_LightOut,uv); //Jitter过的颜色
                
                if(_IgnoreHistory)
                {
                    return Color;
                }
                
                float d = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, UnJitterUV));
                DepthOut = d;

                float2 Closet = GetClosetFragment(uv);

                float2 Motion = tex2D(_GT2,Closet).xy;
                float2 HistoryUV = uv - Motion;
                float4 HistoryColor = tex2D(_HistoryTex,HistoryUV);// 上一帧Jitter过后的颜色

                float3 AABBMin,AABBMax;
                AABBMax = AABBMin = RGBToYCoCg(Color);
                for(int k = 0 ; k < 9 ; k++)
                {
                    float3 C = RGBToYCoCg(tex2D(_LightOut,uv + kOffsets3x3[k] / 1024.0));

                    AABBMin = min(AABBMin, C);
                    AABBMax = max(AABBMax, C);
                }

                float3 HistoryCoCg = RGBToYCoCg(HistoryColor);

                float BlendFactor = saturate(0.05 + length(Motion) * 1000); 

                HistoryColor.rgb = YCoCgToRGB(ClipHistory(HistoryCoCg, AABBMin, AABBMax));

                if(HistoryUV.x < 0 || HistoryUV.y < 0 || HistoryUV.x > 1.0f || HistoryUV.y > 1.0f)
                {
                    BlendFactor = 1.0f;
                }
                
                return lerp(HistoryColor,Color,BlendFactor);
            }

            ENDCG
        }
    }
    CustomEditor "GBufferGUI" 
}