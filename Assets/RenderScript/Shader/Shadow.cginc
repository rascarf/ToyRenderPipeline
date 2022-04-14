#define N_SAMPLE 16

static float2 poissonDisk[16] = {
    float2( -0.94201624, -0.39906216 ),
    float2( 0.94558609, -0.76890725 ),
    float2( -0.094184101, -0.92938870 ),
    float2( 0.34495938, 0.29387760 ),
    float2( -0.91588581, 0.45771432 ),
    float2( -0.81544232, -0.87912464 ),
    float2( -0.38277543, 0.27676845 ),
    float2( 0.97484398, 0.75648379 ),
    float2( 0.44323325, -0.97511554 ),
    float2( 0.53742981, -0.47373420 ),
    float2( -0.26496911, -0.41893023 ),
    float2( 0.79197514, 0.19090188 ),
    float2( -0.24188840, 0.99706507 ),
    float2( -0.81409955, 0.91437590 ),
    float2( 0.19984126, 0.78641367 ),
    float2( 0.14383161, -0.14100790 )
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
    float2 uv = ShadowNdc.xy * 0.5 + 0.5;

    float step = 3.0; // 7 * 7
    
    float D_Average = 0.0;

    float Count = 0.0005; //防止除以0

    for(int i = 0; i < N_SAMPLE;i++)
    {
        float2 UnitOffset = RotateVec2(poissonDisk[i],rotateAngle);
        float2 Offset = UnitOffset * SearchWidth;
        float2 uvo = uv + Offset;

        float D_Sample = tex2D(_ShadowTex,uvo).r;
        if(D_Sample > D_ShadingPoint)
        {
            Count += 1;
            D_Average += D_Sample;
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

    float D_ShadingPoint = ShadowNdc.z;
    float2 uv = ShadowNdc.xy * 0.5 + 0.5;

    //平均遮挡深度
    float SearchWidth = PcssSearchRadius / OrthoWidth;
    float2 Blocker = AverageBlockerDepth(ShadowNdc,_ShadowTex,D_ShadingPoint,SearchWidth,rotateAngle);
    float D_Average = Blocker.x;
    float BlockerCount = Blocker.y;

    if(BlockerCount < 1 ) return 1.0;

    //世界空间下的距离
    float D_Receiver = (1.0 - D_ShadingPoint) * 2 * OrthoDistance;
    float D_Blocker = (1.0 - D_Average) * 2 * OrthoDistance;

    //世界空间下的Filter半径
    float W = (D_Receiver - D_Blocker) * PcssFilterRadius / D_Blocker;

    //深度图上的半径
    float Radius = W / OrthoWidth;

    float Shadow = 0.0f;
   
    for(int i = 0 ; i < N_SAMPLE; i++)
    {
        float2 Offset = poissonDisk[i];
        Offset = RotateVec2(Offset,rotateAngle);
        float2 uvo = uv + Offset * Radius;

        float D_Sample = tex2D(_ShadowTex,uvo).r;
        if(D_Sample > D_ShadingPoint)
            Shadow += 1.0f;
    }

    Shadow /= N_SAMPLE;

    return 1.0 - Shadow;
}