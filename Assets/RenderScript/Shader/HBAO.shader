Shader "DeferedRP/HBAO"
{
 Properties
    {
        _MainTex("Texture",2D) = "white"{}
    }

    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #define FLT_EPSILON     1.192092896e-07
            
            #include "GlobalUniform.cginc"
            #include "UnityCG.cginc"
            #include "Random.cginc"
            #include "Shadow.cginc"

            float4 _UV2View;
            float4 _AOTexSize;

            float _AOStrength;
            float _MaxRadiusPiexel;
            float _RadiusPixel;
            float _AORaidus;
            float _AngleBias;
            float4x4 _ViewMatrix;

            sampler2D _AONoiseTex;

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

            float PositivePow(float base, float power)
            {
                return pow(max(abs(base), float(FLT_EPSILON)), power);
            }

            inline float FetchDepth(float2 uv)
            {
                return SAMPLE_DEPTH_TEXTURE(_GDepth, uv);
            }

            inline float3 FetchViewPos(float2 uv)
            {
                float depth = LinearEyeDepth(FetchDepth(uv));
                return float3((uv * _UV2View.xy + _UV2View.zw) * depth, depth);
            }

            inline float3 FetchViewNormal(float2 uv)
            {
                float3 normal = tex2D(_GT1, uv).rgb * 2 - 1;
                float4 ViewNormal = mul(_ViewMatrix,float4(normal,0.0f));

                return float3(ViewNormal.x, ViewNormal.y, -ViewNormal.z);
            }

            inline float FallOff(float dist)
            {
                return 1 - dist / _AORaidus;
            }

            inline float SimpleAO(float3 pos, float3 stepPos, float3 normal, inout float top)
            {
                float3 h = stepPos - pos;
                float dist = sqrt(dot(h, h));
                float sinBlock = dot(normal, h) / dist;
                float diff = max(sinBlock - top, 0);
                top = max(sinBlock, top);
                return diff * saturate(FallOff(dist));
            }

            inline float random(float2 uv) 
            {
                return frac(sin(dot(uv.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }      


            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float ao = 0;

                float3 ViewPos = FetchViewPos(uv);
                float3 Normal = FetchViewNormal(uv);

                float SetpSize = min((_RadiusPixel / ViewPos.z),_MaxRadiusPiexel) / (4 + 1.0);

                if(SetpSize < 1 )
                {
                    return float4(tex2D(_GT3,uv).xyz,1);
                }

                float Delta = 2.0 * UNITY_PI / 4.0;
                float rnd = random(uv * 10);
                float2 xy = float2(1,0);

                UNITY_UNROLL
                for(int i = 0 ; i < 4 ; i++)
                {
                    float angle = Delta * (float(i) + rnd);
                    float cos, sin;
                    sincos(angle, sin, cos);
                    float2 dir = float2(cos, sin);

                    float rayPixel = 1;
                    float top = _AngleBias;

                    UNITY_UNROLL
                    for(int j = 0; j < 4; ++j)
                    {
                        float2 stepUV = round(rayPixel * dir) * _AOTexSize.xy + uv;
                        float3 stepViewPos = FetchViewPos(stepUV);
                        ao += SimpleAO(ViewPos, stepViewPos, Normal, top);
                        rayPixel += SetpSize;
                    }
                }

                ao /= 4 * 4;

                ao = PositivePow(ao * _AOStrength, 0.6);
                float col = saturate(1 - ao);

                return float4(tex2D(_GT3,uv).xyz, col);
            }          
            ENDCG
        }
    }
}