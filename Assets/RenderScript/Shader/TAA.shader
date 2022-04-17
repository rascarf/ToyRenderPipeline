Shader "DeferedRP/TAA"
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

            sampler2D _MainTex;
            sampler2D _HistoryTex;
            int _IgnoreHistory;
            float2 _Jitter;

            float4 frag(v2f i):SV_Target
            {
                float2 uv = i.uv;

                // #if UNITY_UV_STARTS_AT_TOP
                //     uv.y = 1 -uv.y;
                // #endif

                float4 Color = tex2D(_MainTex,uv);
                if(_IgnoreHistory)
                {
                    return Color;
                }

                 float4 HistoryColor = tex2D(_HistoryTex,uv);
                #if UNITY_UV_STARTS_AT_TOP
                    // float4 HistoryColor = tex2D(_HistoryTex,float2(uv.x, 1 - uv.y));
                #else 
                    // float4 HistoryColor = tex2D(_HistoryTex,uv);
                #endif
                    
                return lerp(HistoryColor,Color,0.05);
            }

            ENDCG
        }
    }
    CustomEditor "GBufferGUI" 
}