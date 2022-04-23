Shader "DeferedRP/SSAO"
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

            //前20个是u
            //后20个是v
            //来自Unity
            static half SSAORandomUV[40] =
            {
                0.00000000,  // 00
                0.33984375,  // 01
                0.75390625,  // 02
                0.56640625,  // 03
                0.98437500,  // 04
                0.07421875,  // 05
                0.23828125,  // 06
                0.64062500,  // 07
                0.35937500,  // 08
                0.50781250,  // 09
                0.38281250,  // 10
                0.98437500,  // 11
                0.17578125,  // 12
                0.53906250,  // 13
                0.28515625,  // 14
                0.23137260,  // 15
                0.45882360,  // 16
                0.54117650,  // 17
                0.12941180,  // 18
                0.64313730,  // 19

                0.92968750,  // 20
                0.76171875,  // 21
                0.13333330,  // 22
                0.01562500,  // 23
                0.00000000,  // 24
                0.10546875,  // 25
                0.64062500,  // 26
                0.74609375,  // 27
                0.67968750,  // 28
                0.35156250,  // 29
                0.49218750,  // 30
                0.12500000,  // 31
                0.26562500,  // 32
                0.62500000,  // 33
                0.44531250,  // 34
                0.17647060,  // 35
                0.44705890,  // 36
                0.93333340,  // 37
                0.87058830,  // 38
                0.56862750,  // 39
            };

            float2 CosSin(float Theta)
            {
                float sn,cs;
                sincos(Theta,sn,cs);
                return float2(cs,sn);
            }

            float GetRandomUVForSSAO(float u ,int sampleIndex)
            {
                return SSAORandomUV[u * 20 + sampleIndex];
            }

            float2 GetScreenSpacePosition(float2 uv)
            {
                return float2(uv * float2(_ScreenWidth,_ScreenHeight));
            }

            float IniterleaveGradientNoise(float2 pixCoord,int frameCount)
            {
                const float3 magic = float3(0.06711056f,0.00583715f,52.9829189f);
                float2 frameMagicScale = float2(20.83f,4.867f);
                pixCoord += frameCount * frameMagicScale;
                return frac(magic.z * frac(dot(pixCoord,magic.xy)));
            }

            float3 PickSamplePoint(float2 uv,int SampleIndex)
            {
                const float2 PositionSS = GetScreenSpacePosition(uv);
                const float gn = float(IniterleaveGradientNoise(PositionSS,SampleIndex));

                const float u = frac(GetRandomUVForSSAO(0.0,SampleIndex) + gn) * 2.0 - 1.0;
                const float theta = (GetRandomUVForSSAO(float(1.0),SampleIndex) + gn) * 6.28318;
                
                return float3(CosSin(theta) * sqrt(1.0 - u * u),u);
            }

            sampler2D _MainTex;

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                //获得深度和法线
                float3 normal = tex2D(_GT1, uv).rgb * 2 - 1;
                float d = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, uv));

                //还原出来的点
                float4 worldPos = mul(_vpMatrixInv, float4(uv*2-1, d, 1));
                worldPos /= worldPos.w;

                // float3 random = tex2D(_SSAONoiseTex,uv).xyz;
                // float3 Tangent = normalize(random - normal * dot(random,normal));
                // float3 Bitangent = cross(normal,Tangent);
                // float3x3 TBN = float3x3(Tangent, Bitangent, normal);
                // float occlusion = 0.0;

                // for(int i = 0 ; i < 64 ; i++)
                // {
                //     float3 Sample = mul(TBN,_SSAOKernel[i].xyz);

                //     Sample = worldPos + Sample * 0.035;

                //     float4 Offset = float4(Sample,1.0);
                //     Offset = mul(_vpMatrix,Offset);
                //     Offset.xyz /= Offset.w;
                //     Offset.xyz = Offset.xyz * 0.5 + 0.5;

                //     float sampleDepth = tex2D(_GDepth, Offset.xy);
                //     float rangeCheck = smoothstep(0.0, 1.0, 0.035 / abs(d - sampleDepth));

                //     occlusion += (sampleDepth >= d ? 1.0 : 0.0) * rangeCheck;
                // }

                // occlusion = max(0.01, (1.0 - (occlusion / 1.0)));
                // occlusion = pow(occlusion, _SSAOStrength);

                // return float4(tex2D(_GT3,uv),d)

                const float rcpSampleCount = 1 / 20.0;
                const float Radius = 0.5;
                float ao = 0.0;

                //先获取随机方向，再根据循环索引确定距离，从而得到点的位置
                for(int s = 0; s < 20 ; s++)
                {
                    float3 v_s1  = PickSamplePoint(uv,s);
                    v_s1  *= sqrt( s + 1.0) * Radius;
                    v_s1  = faceforward(v_s1 , -normal , v_s1);

                    //采样点的世界坐标
                    float3 vpos = worldPos + v_s1;

                    //裁剪空间的点
                    float4 pos = mul(_vpMatrix,float4(vpos,1.0f));

                    //NDC下的点
                    pos /= pos.w;

                    //uv下的点
                    float2 nuv = pos.xy * 0.5 + 0.5;

                    //采样点的深度
                    float nd = UNITY_SAMPLE_DEPTH(tex2D(_GDepth, nuv));

                    //ShadingPoint到采样点的向量
                    float3 v_s2 = pos - worldPos;

                    //采样向量与法线的夹角
                    float DotVal = dot(v_s2,normal);

                    float RangeCheck = smoothstep(0.0,1.0,0.1 / abs(d - nd));

                    //ReverseZ
                    if(nd <= pos.z) // 离得远一些
                        ao += 1.0 * RangeCheck;
                }

                ao = ao * rcpSampleCount;

                return float4(tex2D(_GT3,uv).xyz,ao);

            }          
            ENDCG
        }
    }
}