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
            sampler2D _OnlyTAA;
            sampler2D _GDepth;
            int _IgnoreHistory;
            float2 _Jitter;

            float4 frag(v2f i,float DepthOut : SV_Depth):SV_Target
            {
                //这个是WriteTexture的uv
                float2 uv = i.uv;

                float d = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, uv));
                DepthOut = d;

                float4 Color = tex2D(_OnlyTAA,uv);
                if(_IgnoreHistory)
                {
                    return Color;
                }

                float4 HistoryColor = tex2D(_HistoryTex,uv);
        
                return lerp(HistoryColor,Color,0.05);
            }

            ENDCG
        }
    }
    CustomEditor "GBufferGUI" 
}