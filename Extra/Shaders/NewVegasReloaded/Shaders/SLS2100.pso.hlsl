//
// Generated by Microsoft (R) HLSL Shader Compiler 9.23.949.2378
//
// Parameters:

float4 AmbientColor : register(c1);
sampler2D BaseMap[7] : register(s0);
sampler2D NormalMap[7] : register(s7);
float4 PSLightColor[10] : register(c3);
float4 TESR_FogColor : register(c15);
float4 PSLightDir : register(c18);
float4 TESR_ShadowData : register(c32);
sampler2D TESR_ShadowMapBufferNear : register(s14) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };
sampler2D TESR_ShadowMapBufferFar : register(s15) = sampler_state { ADDRESSU = CLAMP; ADDRESSV = CLAMP; MAGFILTER = LINEAR; MINFILTER = LINEAR; MIPFILTER = LINEAR; };

// Registers:
//
//   Name         Reg   Size
//   ------------ ----- ----
//   AmbientColor const_1       1
//   PSLightColor[0] const_3       1
//   PSLightDir   const_18      1
//   BaseMap      texture_0       2
//   NormalMap    texture_7       2
//


// Structures:

struct VS_INPUT {
	float3 LCOLOR_0 : COLOR0;
    float3 BaseUV : TEXCOORD0;
    float3 texcoord_1 : TEXCOORD1_centroid;
    float3 texcoord_3 : TEXCOORD3_centroid;
    float3 texcoord_4 : TEXCOORD4_centroid;
    float3 texcoord_5 : TEXCOORD5_centroid;
	float4 texcoord_6 : TEXCOORD6;
    float4 texcoord_7 : TEXCOORD7;
};

struct PS_OUTPUT {
    float4 color_0 : COLOR0;
};

#include "Includes/Shadow.hlsl"

PS_OUTPUT main(VS_INPUT IN) {
    PS_OUTPUT OUT;

#define	expand(v)		(((v) - 0.5) / 0.5)
#define	compress(v)		(((v) * 0.5) + 0.5)
#define	shade(n, l)		max(dot(n, l), 0)
#define	shades(n, l)		saturate(dot(n, l))

    float3 m17;
    float3 q0;
    float3 q1;
    float3 q2;
    float3 q21;
    float3 q6;
    float4 r0;
    float4 r1;
    float4 r2;
    float4 r3;

    r0.xyzw = tex2D(NormalMap[1], IN.BaseUV.xy);
    r1.xyzw = tex2D(NormalMap[0], IN.BaseUV.xy);
    r2.xyzw = tex2D(BaseMap[1], IN.BaseUV.xy);
    r3.xyzw = tex2D(BaseMap[0], IN.BaseUV.xy);
    q0.xyz = normalize(IN.texcoord_4.xyz);
    q1.xyz = normalize(IN.texcoord_3.xyz);
    q21.xyz = normalize((2 * ((r1.xyz - 0.5) * IN.LCOLOR_0.x)) + (2 * ((r0.xyz - 0.5) * IN.LCOLOR_0.y)));	// [0,1] to [-1,+1]
    q2.xyz = normalize(IN.texcoord_5.xyz);
    m17.xyz = mul(float3x3(q1.xyz, q0.xyz, q2.xyz), PSLightDir.xyz);
    r2.w = shades(q21.xyz, m17.xyz);
    q6.xyz = ((GetLightAmount(IN.texcoord_6, IN.texcoord_7) * (r2.w * PSLightColor[0].rgb)) + AmbientColor.rgb) * ((IN.LCOLOR_0.x * r3.xyz) + (r2.xyz * IN.LCOLOR_0.y));
    r1.xyz = q6.xyz * IN.texcoord_1.xyz;
    OUT.color_0.a = 1;
    OUT.color_0.rgb = (IN.BaseUV.z * (TESR_FogColor.xyz - (IN.texcoord_1.xyz * q6.xyz))) + r1.xyz;

    return OUT;
};

// approximately 37 instruction slots used (4 texture, 33 arithmetic)