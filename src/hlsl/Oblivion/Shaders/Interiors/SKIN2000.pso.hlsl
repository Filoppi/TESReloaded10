//
// Generated by Microsoft (R) D3DX9 Shader Compiler 9.08.299.0000
//
// Parameters:

float4 AmbientColor : register(c1);
float4 PSLightColor[4] : register(c2);
float4 Toggles : register(c7);
float4 TESR_SkinData : register(c8);
float4 TESR_SkinColor : register(c9);
float4 TESR_ShadowData : register(c10);
float4 TESR_ShadowLightPosition[4] : register(c11);
float4 TESR_ShadowCubeMapBlend : register(c15);

sampler2D BaseMap : register(s0);
sampler2D NormalMap : register(s1);
sampler2D FaceGenMap0 : register(s2);
sampler2D FaceGenMap1 : register(s3);
samplerCUBE TESR_ShadowCubeMapBuffer0 : register(s8) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; ADDRESSW = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

// Registers:
//
//   Name         Reg   Size
//   ------------ ----- ----
//   AmbientColor const_1       1
//   PSLightColor[0] const_2        1
//   Toggles      const_7       1
//   BaseMap      texture_0       1
//   NormalMap    texture_1       1
//   FaceGenMap0  texture_2       1
//   FaceGenMap1  texture_3       1
//


// Structures:

struct VS_INPUT {
    float2 BaseUV : TEXCOORD0;
    float3 texcoord_1 : TEXCOORD1_centroid;
    float3 texcoord_6 : TEXCOORD6_centroid;
	float4 texcoord_7 : TEXCOORD7;
    float3 LCOLOR_0 : COLOR0;
    float4 LCOLOR_1 : COLOR1;
};

struct VS_OUTPUT {
    float4 color_0 : COLOR0;
};

#include "..\Includes\Skin.hlsl"
#include "..\Includes\ShadowCube.hlsl"

VS_OUTPUT main(VS_INPUT IN) {
    VS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)
#define	shade(n, l)		max(dot(n, l), 0)
#define	shades(n, l)	saturate(dot(n, l))
#define	weight(v)		dot(v, 1)
#define	sqr(v)			((v) * (v))

    float3 noxel1;
    float3 q0;
    float3 q11;
    float3 q2;
    float1 q4;
    float3 q6;
    float3 q8;
    float3 q9;
    float4 r0;
    float4 r1;
    float4 r2;
    float3 r3;
	float3 camera;
	float Shadow = 1.0f;
	
	if (TESR_ShadowLightPosition[0].w) Shadow *= GetLightAmountSkin(TESR_ShadowCubeMapBuffer0, IN.texcoord_7, TESR_ShadowLightPosition[0], TESR_ShadowCubeMapBlend.x);
    noxel1.xyz = tex2D(NormalMap, IN.BaseUV.xy).xyz;
    r2.xyzw = tex2D(FaceGenMap1, IN.BaseUV.xy);
    r1.xyzw = tex2D(FaceGenMap0, IN.BaseUV.xy);
    r0.xyzw = tex2D(BaseMap, IN.BaseUV.xy);
    q2.xyz = normalize(expand(noxel1.xyz));
    q11.xyz = 2 * ((2 * r2.xyz) * (expand(r1.xyz) + r0.xyz));
	camera = normalize(IN.texcoord_6.xyz);	
    q4.x = 1 - shade(q2.xyz, camera);
    q0.xyz = (Toggles.x <= 0.0 ? q11.xyz : (q11.xyz * IN.LCOLOR_0.xyz));
    r3.xyz = ((q4.x * sqr(q4.x)) * PSLightColor[0].rgb) * 0.5;
	q6.xyz = shade(q2.xyz, IN.texcoord_1.xyz) * PSLightColor[0].rgb + r3.xyz;
	
	q6.xyz = Shadow * Skin(q6, PSLightColor[0].rgb, camera, IN.texcoord_1, q2) + AmbientColor.rgb;
	
    q8.xyz = max(q6.xyz, 0) * q0.xyz;
    q9.xyz = (Toggles.y <= 0.0 ? q8.xyz : ((IN.LCOLOR_1.w * (IN.LCOLOR_1.xyz - q8.xyz)) + q8.xyz));
    OUT.color_0.a = r0.w * AmbientColor.a;
    OUT.color_0.rgb = q9.xyz;
    return OUT;
	
};

// approximately 37 instruction slots used (4 texture, 33 arithmetic)