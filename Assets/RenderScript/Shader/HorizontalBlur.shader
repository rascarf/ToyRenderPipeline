Shader "DeferedRP/HorizontalBlur"
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
            #include "Shadow.cginc"
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

                float shadow = 0;
                float weight = 0;
                float r = 3;

                //计算Camera和当前像素点的距离
                float Dis = distance(_WorldSpaceCameraPos.xyz,worldPos.xyz);
                float Radius = 1.0 / (pow(Dis,1.2) * 0.01 + 0.01);

                for(int i = -r; i <= r;i++)
                {
                    float2 offset = float2(i,0) / float2(_ScreenWidth / 4,_ScreenHeight / 4);
                    float2 uv_Sample = uv + offset * Radius;
                    shadow += tex2D(_MainTex,uv_Sample).r;
                    weight += 1;
                }

                shadow /= weight;

                return shadow;
            }          
            ENDCG
        }
    }
}