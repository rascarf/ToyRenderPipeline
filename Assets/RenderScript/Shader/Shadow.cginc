#define N_SAMPLE 64
static float2 poissonDisk[N_SAMPLE] = {
    float2(-0.5119625f, -0.4827938f),
    float2(-0.2171264f, -0.4768726f),
    float2(-0.7552931f, -0.2426507f),
    float2(-0.7136765f, -0.4496614f),
    float2(-0.5938849f, -0.6895654f),
    float2(-0.3148003f, -0.7047654f),
    float2(-0.42215f, -0.2024607f),
    float2(-0.9466816f, -0.2014508f),
    float2(-0.8409063f, -0.03465778f),
    float2(-0.6517572f, -0.07476326f),
    float2(-0.1041822f, -0.02521214f),
    float2(-0.3042712f, -0.02195431f),
    float2(-0.5082307f, 0.1079806f),
    float2(-0.08429877f, -0.2316298f),
    float2(-0.9879128f, 0.1113683f),
    float2(-0.3859636f, 0.3363545f),
    float2(-0.1925334f, 0.1787288f),
    float2(0.003256182f, 0.138135f),
    float2(-0.8706837f, 0.3010679f),
    float2(-0.6982038f, 0.1904326f),
    float2(0.1975043f, 0.2221317f),
    float2(0.1507788f, 0.4204168f),
    float2(0.3514056f, 0.09865579f),
    float2(0.1558783f, -0.08460935f),
    float2(-0.0684978f, 0.4461993f),
    float2(0.3780522f, 0.3478679f),
    float2(0.3956799f, -0.1469177f),
    float2(0.5838975f, 0.1054943f),
    float2(0.6155105f, 0.3245716f),
    float2(0.3928624f, -0.4417621f),
    float2(0.1749884f, -0.4202175f),
    float2(0.6813727f, -0.2424808f),
    float2(-0.6707711f, 0.4912741f),
    float2(0.0005130528f, -0.8058334f),
    float2(0.02703013f, -0.6010728f),
    float2(-0.1658188f, -0.9695674f),
    float2(0.4060591f, -0.7100726f),
    float2(0.7713396f, -0.4713659f),
    float2(0.573212f, -0.51544f),
    float2(-0.3448896f, -0.9046497f),
    float2(0.1268544f, -0.9874692f),
    float2(0.7418533f, -0.6667366f),
    float2(0.3492522f, 0.5924662f),
    float2(0.5679897f, 0.5343465f),
    float2(0.5663417f, 0.7708698f),
    float2(0.7375497f, 0.6691415f),
    float2(0.2271994f, -0.6163502f),
    float2(0.2312844f, 0.8725659f),
    float2(0.4216993f, 0.9002838f),
    float2(0.4262091f, -0.9013284f),
    float2(0.2001408f, -0.808381f),
    float2(0.149394f, 0.6650763f),
    float2(-0.09640376f, 0.9843736f),
    float2(0.7682328f, -0.07273844f),
    float2(0.04146584f, 0.8313184f),
    float2(0.9705266f, -0.1143304f),
    float2(0.9670017f, 0.1293385f),
    float2(0.9015037f, -0.3306949f),
    float2(-0.5085648f, 0.7534177f),
    float2(0.9055501f, 0.3758393f),
    float2(0.7599946f, 0.1809109f),
    float2(-0.2483695f, 0.7942952f),
    float2(-0.4241052f, 0.5581087f),
    float2(-0.1020106f, 0.6724468f)
};

float ShadowMap01(float4 WorldPos,sampler2D _ShadowTex,float4x4 _ShadowVpMatrix)
{
    //光空间下的点
    float4 ShadowNdc = mul(_ShadowVpMatrix,WorldPos);

    ShadowNdc /= ShadowNdc.w;

    //映射到[0,1]
    float2 uv = ShadowNdc.xy * 0.5 +0.5;

    if(uv.x< 0 || uv.x>1 || uv.y<0||uv.y>1) return 1.0f;

    float d = ShadowNdc.z;
    float d_Sample = tex2D(_ShadowTex,uv).r;

    if(d_Sample > d) return 0.0f;

    return 1.0f;
}

float PCF3X3(float4 WorldPos,sampler2D _ShadowTex,float4x4 _ShadowVpMatrix,float ShadowMapResolution,float bias)
{
    float4 ShadowNdc = mul(_ShadowVpMatrix,WorldPos);
    ShadowNdc /= ShadowNdc.w;

    float2 uv = ShadowNdc.xy * 0.5 + 0.5;

    float D_Shading_Point = ShadowNdc.z;
    float Shadow = 0.0;

    for(int i = -1; i <= 1 ; i++)
    {
        for(int j = -1; j <= 1 ; j++)
        {
            float2 Offset = float2(i,j) / ShadowMapResolution;
            float D_Sample = tex2D(_ShadowTex,uv + Offset).r;

            if(D_Sample - bias > D_Shading_Point)
            Shadow += 1.0;
        }
    }

    return 1.0 - (Shadow / 9.0);
}

float2 RotateVec2(float2 V,float Angle)
{
    float s = sin(Angle);
    float c = cos(Angle);

    return float2(V.x * c + V.y *s, -V.x *s + V.y * c);
}

//计算Bloker的平均深度,后面可以直接计算PCF滤波的范围
float2 AverageBlockerDepth(float4 ShadowNdc,sampler2D _ShadowTex,float D_ShadingPoint,float SearchWidth,float rotateAngle)
{
    float2 uv = ShadowNdc.xy * 0.5 + 0.5; //ShadingPoint在ShadowMap上的UV
 
    float D_Average = 0.0; //要输出的结果

    float Count = 0.0005; //防止除以0

    for(int i = 0; i < N_SAMPLE;i++) //多次采样（只是半影区域）
    {
        float2 UnitOffset = RotateVec2(poissonDisk[i],rotateAngle); //随机得到旋转方向
        float2 Offset = UnitOffset * SearchWidth; //得到当前采样点偏移
        float2 uvo = uv + Offset; // 计算得到采样点

        float D_Sample = tex2D(_ShadowTex,uvo).r; //采样当前的随机点，这里带来噪音
        if(D_Sample > D_ShadingPoint)
        {
            Count += 1;
            D_Average += D_Sample; //计算Blocker平均距离
        }

    }

    return float2(D_Average / Count , Count);
}

float ShadowMapPCSS
(
    float4 WorldPos,sampler2D _ShadowTex,float4x4 _ShadowVpMatrix,
    float OrthoWidth,float OrthoDistance,float ShadowMapResolution,float rotateAngle,
    float PcssSearchRadius, float PcssFilterRadius
)
{
    float4 ShadowNdc = mul(_ShadowVpMatrix,WorldPos);
    ShadowNdc /= ShadowNdc.w;

    float D_ShadingPoint = ShadowNdc.z; //ShadingPoint的深度
    float2 uv = ShadowNdc.xy * 0.5 + 0.5;

    //平均遮挡深度
    float SearchWidth = PcssSearchRadius / OrthoWidth; //用来模拟光的体积
    float2 Blocker = AverageBlockerDepth(ShadowNdc,_ShadowTex,D_ShadingPoint,SearchWidth,rotateAngle);
    float D_Average = Blocker.x; //求得平均距离
    float BlockerCount = Blocker.y;

    if(BlockerCount < 1 ) return 1.0; // 如果完全没被遮挡，直接肯定不在阴影内

    //世界空间下的距离
    float D_Receiver = (1.0 - D_ShadingPoint) * 2 * OrthoDistance; // 前面是深度 后面是视锥深度
    float D_Blocker = (1.0 - D_Average) * 2 * OrthoDistance; // 痛

    //世界空间下的Filter半径
    float W = (D_Receiver - D_Blocker) * PcssFilterRadius / D_Blocker; //计算得到Filter半径

    //转换到光空间内的Filter半径
    float Radius = W / OrthoWidth; 

    float Shadow = 0.0f;
   
    for(int i = 0 ; i < N_SAMPLE; i++)
    {
        float2 Offset = poissonDisk[i];
        Offset = RotateVec2(Offset,rotateAngle);
        float2 uvo = uv + Offset * Radius; //算得随机采样点

        float D_Sample = tex2D(_ShadowTex,uvo).r;
        if(D_Sample > D_ShadingPoint)
            Shadow += 1.0f;
    }

    Shadow /= N_SAMPLE; //得到有噪点的结果，后面需要滤波

    return 1.0 - Shadow;
}

float FilterESM(float2 uv,float _ShadowMapResolution,float _ESMConst,sampler2D _ShadowTex)
{
    float CD = 0.0;
    float2 uvOffset = 1.0 / _ShadowMapResolution;

    //高斯滤波
    const float gussianKernel[9] = 
        {
            0.077847, 0.123317, 0.077847,
            0.123317, 0.195346, 0.123317,
            0.077847, 0.123317, 0.077847,
        };

    for (int x = -1; x <= 1; ++x) 
    {
        for (int y = -1; y <= 1; ++y) 
        {

            float d = tex2D(_ShadowTex, uv + float2(x, y) * uvOffset).r;
            d = 1.0 -d;

            float weight = gussianKernel[x * 3 + y + 4];
            CD += weight * exp(_ESMConst * (d));
        }
    }
    
    //距离滤波
    // float4 TexCol = 0;
    // float v = 0;
    // float ALLp = 0;
    // int c = 3;  
    // for (int x = -c; x <= c; ++x) 
    // {
    //     for (int y = -c; y <= c; ++y) 
    //     {
    //         float p = 1.0 / max(0.5,pow(length(float2(x,y)),2));

    //         v += exp(80 * (1 - tex2D(_ShadowTex,uv + float2(x,y) / 1024.0).r)) * p;

    //         ALLp += p;
    //     }
    // }
    // CD = v / ALLp;


    return CD;
}

float ESM(float4 WorldPos,sampler2D _ShadowMap,float4x4 _ShadowVpMatrix,float ESMConst)
{
    float4 ShadowNdc = mul(_ShadowVpMatrix,WorldPos);
    ShadowNdc /= ShadowNdc.w;

    float2 uv = ShadowNdc.xy * 0.5 + 0.5;

    float ZBase = tex2D(_ShadowMap,uv.xy);

    float d =  1 - ShadowNdc.z;

    // e^(cz) * e^(-cd)
    float esm = saturate((exp(-ESMConst * d) * ZBase));

    return esm ;
}
