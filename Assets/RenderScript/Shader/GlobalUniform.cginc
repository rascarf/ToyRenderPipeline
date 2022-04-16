sampler2D _GDepth;
sampler2D _GT0;
sampler2D _GT1;
sampler2D _GT2;
sampler2D _GT3;

samplerCUBE _DiffuseIBL;
samplerCUBE _SpecularIBL;
sampler2D _BrdfIBL;
sampler2D _NoiseTex;

sampler2D _ShadowMask;
sampler2D _ShadowStrength;
sampler2D _ShadowTex0;
sampler2D _ShadowTex1;
sampler2D _ShadowTex2;
sampler2D _ShadowTex3;

sampler2D _ESM0;
sampler2D _ESM1;
sampler2D _ESM2;
sampler2D _ESM3;

float _Split0;
float _Split1;
float _Split2;
float _Split3;

float _OrthoWidth0;
float _OrthoWidth1;
float _OrthoWidth2;
float _OrthoWidth3;

float _PcssSearchRadius0;
float _PcssSearchRadius1;
float _PcssSearchRadius2;
float _PcssSearchRadius3;

float _PcssFilterRadius0;
float _PcssFilterRadius1;
float _PcssFilterRadius2;
float _PcssFilterRadius3;

float _ShadingPointNormalBias0;
float _ShadingPointNormalBias1;
float _ShadingPointNormalBias2;
float _ShadingPointNormalBias3;

float _DepthNormalBias0;
float _DepthNormalBias1;
float _DepthNormalBias2;
float _DepthNormalBias3;

float4x4 _ShadowVpMatrix0;
float4x4 _ShadowVpMatrix1;
float4x4 _ShadowVpMatrix2;
float4x4 _ShadowVpMatrix3;

float4x4 _vpMatrix;
float4x4 _vpMatrixInv;

float _UsingShadowMask;
float _OrthoDistance;
float _ShadowMapResolution;
float _NoiseTexResolution;
float _ScreenWidth;
float _ScreenHeight;
float _Far;
float _Near;
float _ESMConst;