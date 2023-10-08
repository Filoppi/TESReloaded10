// Shader to blend cloud layers from weathers transitions with the sky
//
// Parameters:

float2 Params : register(c4);
sampler2D TexMap : register(s0);
sampler2D TexMapBlend : register(s1);

float4 TESR_DebugVar : register(c5);
float4 TESR_SunColor : register(c6);
float4 TESR_SkyColor : register(c7);
float4 TESR_SkyLowColor : register(c8);
float4 TESR_HorizonColor : register(c9);
float4 TESR_SunDirection : register(c10);
float4 TESR_SkyData : register(c11);   // x:AthmosphereThickness y:SunInfluence z:SunStrength w:StarStrength
float4 TESR_CloudData : register(c12); // x:UseNormals y:SphericalNormals z:Transparency
float4 TESR_SunAmount : register(c13);
float4 TESR_SunPosition : register(c14);


// Registers:
//
//   Name         Reg   Size
//   ------------ ----- ----
//   Params       const_4       1
//   TexMap       texture_0       1
//   TexMapBlend  texture_1       1
//


static const float UseNormals = TESR_CloudData.x;
static const float SphericalNormals = TESR_CloudData.y;
static const float SUNINFLUENCE = 1/TESR_SkyData.y;

// Structures:

struct VS_INPUT {
    float2 TexUV : TEXCOORD0;
    float2 position: VPOS;
    float2 TexBlendUV : TEXCOORD1;
    float3 location: TEXCOORD2;
    float4 color_0 : COLOR0;
    float4 color_1 : COLOR1;
};

struct VS_OUTPUT {
    float4 color_0 : COLOR0; // sunglare active region/suncolor
};

// Code:
#include "Includes/Helpers.hlsl"
#include "Includes/Position.hlsl"

float3 getNormal(float2 partial, float3 eyeDir){

    // if spherical normals are not activated, we must convert the normals pointing up
    if (!SphericalNormals){
        float2 dir = normalize(eyeDir.xy);
        float2x2 R = {{dir.x, dir.y}, { dir.y, -dir.x}};
        partial = compress(mul(expand(partial.xy), R));
        partial.y = 1 - partial.y;
    }

    partial = expand(partial);

    // reconstruct Z component
    float z = sqrt(1 - saturate(dot(partial, partial)));
    float3 normal = normalize(float3(partial, z));

    // get TBN matrix by getting the plane perpendicular to the eye direction
    // http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-13-normal-mapping/
    float3 N = eyeDir;
    float3 T = float3(N.y, -N.x, 0);  // horizontal X axis. Maybe we could rotate it to get spherical normals?
    float3 B = cross(T, N);
    // float3 B = cross(N, T);

    float3x3 TBN = {T, B, N};
    return normalize(mul(normal, TBN));
}

VS_OUTPUT main(VS_INPUT IN) {
    VS_OUTPUT OUT;

    float3 up = float3(0, 0, 1);
    float3 eyeDir = normalize(IN.location);
    float verticality = pows(compress(dot(eyeDir, up)), 3);
    float sunHeight = shade(TESR_SunPosition.xyz, up);

    float sunDir = compress(dot(eyeDir, TESR_SunPosition.xyz)); // stores wether the camera is looking in the direction of the sun in range 0/1

    float athmosphere = pows(1 - verticality, 8) * TESR_SkyData.x;
    float sunInfluence = pows(sunDir, SUNINFLUENCE);

    float cloudsPower = Params.x;
    float4 cloudsWeather1 = tex2D(TexMap, IN.TexUV.xy);
    float4 cloudsWeather2 = tex2D(TexMapBlend, IN.TexBlendUV.xy);

    float4 cloudsWeatherBlend = lerp(cloudsWeather1, cloudsWeather2, cloudsPower); // weather transition

    float4 finalColor = (weight(cloudsWeather1.xyz) == 0.0 ? cloudsWeather2 : (weight(cloudsWeather2.xyz) == 0.0 ? cloudsWeather1 : cloudsWeatherBlend)); // select either weather or blend
    finalColor.a = cloudsWeatherBlend.a;
    // finalColor = cloudsWeather1;

    if (IN.color_1.r){ // early out if this texture is sun/moon
        OUT.color_0 = float4(finalColor.rgb * IN.color_0.rgb * Params.y, finalColor.w * IN.color_0.a);
        return OUT;
    }

    // shade clouds 
    float greyScale = lerp(luma(finalColor), 1, TESR_CloudData.w);
    float alpha = finalColor.w * TESR_CloudData.z;

    float3 sunColor = TESR_SunColor; // increase suncolor strength with sun height
    float sunSet = saturate(pows(1 - sunHeight, 8) * TESR_SkyData.x);
    sunColor = lerp(sunColor, sunColor + float3(1, 0, 0.03) * TESR_SunAmount.x, sunSet); // add extra red to the sun at sunsets

    // calculate sky color to blend in the clouds
    float3 skyColor = lerp(TESR_SkyLowColor.rgb, TESR_SkyColor.rgb, verticality);
    skyColor = lerp(skyColor, TESR_HorizonColor.rgb, saturate(athmosphere * (0.5 + sunInfluence)));
    skyColor += sunInfluence * (1 - sunHeight) * lerp(0.5, 1, athmosphere) * sunColor * TESR_SkyData.z * TESR_SunAmount.x;

    float3 scattering = sunInfluence * lerp(0.3, 1, 1 - alpha) * (skyColor + sunColor) * 0.3;

    if ( UseNormals){
        // Tests for normals lit cloud
        float2 normal2D = finalColor.xy; // normal x and y are in red and green, blue is reconstructed
        float3 normal = getNormal(normal2D, -eyeDir); // reconstruct world normal from red and green

        greyScale = lerp(TESR_CloudData.w, 1, finalColor.z); // greyscale is stored in blue channel
        float3 ambient = skyColor * greyScale * lerp(0.5, 0.7, sunDir); // fade ambient with sun direction
        float3 diffuse = compress(dot(normal, TESR_SunPosition.xyz)) * sunColor * (1 - luma(ambient)) * lerp(0.8, 1, sunDir); // scale diffuse if ambient is high
        float3 fresnel = pows(1 - shade(-eyeDir, normal), 4) * pows(saturate(expand(sunDir)), 2) * shade(normal, up) * (sunColor + skyColor) * 0.2;
        float3 bounce = shade(normal, -up) * TESR_HorizonColor.rgb * 0.1 * sunHeight; // light from the ground bouncing up to the underside of clouds

        finalColor = float4(ambient + diffuse + fresnel + scattering + bounce, alpha);
        // finalColor.rgb = selectColor(TESR_DebugVar.x, finalColor, ambient, diffuse, fresnel, bounce, scattering, sunColor, skyColor, normal, float3(IN.TexUV, 1));
    } else {

        // simply tint the clouds
        float sunInfluence = 1 - pow(sunDir, 3.0);
        float3 cloudTint = lerp(pow(TESR_SkyLowColor.rgb, 5.0), sunColor * 1.5, saturate(sunInfluence * saturate(greyScale))).rgb;
        cloudTint = lerp(cloudTint, white.rgb, sunHeight); // tint the clouds less when the sun is high in the sky

        float dayLight = saturate(luma(sunColor));

        finalColor.rgb *= cloudTint * TESR_CloudData.w;
        finalColor.rgb += scattering;
    }
    
    OUT.color_0 = float4(finalColor.rgb * Params.y, finalColor.w * IN.color_0.a * TESR_CloudData.z);
    return OUT;
};