Shader "DeferedRP/NormalVerticalBlur"
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
            
            #include "GlobalUniform.cginc"
            #include "UnityCG.cginc"
            #include "Random.cginc"
            #include "Shadow.cginc"


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

            sampler2D _MainTex;

            float frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float3 normal = tex2D(_GT1, uv).rgb * 2 - 1;
                float d = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, uv));
                float4 worldPos = mul(_vpMatrixInv, float4(uv*2-1, d, 1));
                worldPos /= worldPos.w;

                float Val = 0;
                float weight = 0;
                float r = 3;

                //计算Camera和当前像素点的距离
                float Radius = 3.0;

                for(int i = -r; i <= r;i++)
                {
                    float2 offset = float2(0,i) / float2(_ScreenWidth,_ScreenHeight);
                    float2 uv_Sample = uv + offset;
                    Val += tex2D(_MainTex,uv_Sample).r;
                    weight += 1;
                }

                Val /= weight;

                return Val;
            }          
            ENDCG
        }
    }
}