Shader "DeferedRP/ESMFilter"
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

            sampler2D _MainTex;

            float frag(v2f i):SV_Target
            {
                float2 uv = i.uv;

                float Shadow = 0;

                Shadow = FilterESM(uv,_ShadowMapResolution,_ESMConst,_MainTex);
                    
                return Shadow;
            }

            ENDCG
        }
    }
}