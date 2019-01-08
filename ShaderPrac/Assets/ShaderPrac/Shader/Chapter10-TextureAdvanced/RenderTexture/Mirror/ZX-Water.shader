// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "ZX/Water" { 
Properties {
	_WaveScale ("Wave scale", Range (0.02,0.15)) = 0.063
	_ReflDistort ("Reflection distort", Range (0,1.5)) = 0.44
	_RefrDistort ("Refraction distort", Range (0,1.5)) = 0.40
	_RefrColor ("Refraction color", COLOR)  = ( .34, .85, .92, 1)
	[NoScaleOffset] _Fresnel ("Fresnel (A) ", 2D) = "gray" {}
	[NoScaleOffset] _BumpMap ("Normalmap ", 2D) = "bump" {}
	WaveSpeed ("Wave speed (map1 x,y; map2 x,y)", Vector) = (19,9,-16,-7)
	[NoScaleOffset] _ReflectiveColor ("Reflective color (RGB) fresnel (A) ", 2D) = "" {}
	_HorizonColor ("Simple water horizon color", COLOR)  = ( .172, .463, .435, 1)
	 _ReflectionTex ("Internal Reflection", 2D) = "" {}
//	 _RefractionTex ("Internal Refraction", 2D) = "" {}
	 _FogPower("FogPower",Range (0,1)) = 0
//	 _InvFadeParemeter ("Auto blend parameter (Edge, Shore, Distance scale)", Vector) = (0.15 ,0.15, 0.5, 1.0)
}


// -----------------------------------------------------------
// Fragment program cards


Subshader { 
	Tags { "LightMode"="ForwardBase" "WaterMode"="Refractive" "Queue" = "Transparent" "RenderType"="Opaque" "IgnoreProjector" = "True" }
	//Tags{"Queue" = "Transparent+1" "RenderType"="Opaque"}
//					Stencil{
//				Ref 0
//				Comp Equal
//				Pass Keep
//			}
	Pass {

	Blend SrcAlpha OneMinusSrcAlpha
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fog
#pragma multi_compile WATER_REFLACTIVE WATER_SIMPLE 
#pragma multi_compile WATER_EDGEBLEND_ON WATER_EDGEBLEND_OFF
#if defined (WATER_REFLACTIVE)
#define HAS_REFLECTION 1
#endif
//#if defined (WATER_REFLACTIVE)
//#define HAS_REFRACTION 1
//#endif


#include "UnityCG.cginc"

uniform half4 _WaveScale4;
uniform half4 _WaveOffset;
fixed _FogPower;
#if HAS_REFLECTION
uniform half _ReflDistort;
#endif
#if HAS_REFRACTION
uniform half _RefrDistort;
#endif

struct appdata {
	fixed4 vertex : POSITION;
	fixed3 normal : NORMAL;
};

struct v2f {
	fixed4 pos : SV_POSITION;
	#if defined(HAS_REFLECTION)
		half4 ref : TEXCOORD0;
		half2 bumpuv0 : TEXCOORD1;
		half2 bumpuv1 : TEXCOORD2;
		half3 viewDir : TEXCOORD3;
	#else
		half2 bumpuv0 : TEXCOORD0;
		half2 bumpuv1 : TEXCOORD1;
		half3 viewDir : TEXCOORD2;
	#endif
	UNITY_FOG_COORDS(4)
};

v2f vert(appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos (v.vertex);
	

	// scroll bump waves
	half4 temp;
	half4 wpos = mul (unity_ObjectToWorld, v.vertex);
	temp.xyzw = wpos.xzxz * _WaveScale4 + _WaveOffset;
	o.bumpuv0 = temp.xy;
	o.bumpuv1 = temp.wz;
	
	// object space view direction (will normalize per pixel)
	o.viewDir.xzy = WorldSpaceViewDir(v.vertex);
	
	#if defined(HAS_REFLECTION) 
	o.ref = ComputeScreenPos(o.pos);
	#endif

	UNITY_TRANSFER_FOG(o,o.pos);	
	return o;
}

#if defined (WATER_REFLACTIVE)
sampler2D _ReflectionTex;
#endif
#if  defined (WATER_SIMPLE)
sampler2D _ReflectiveColor;
#endif
#if defined (WATER_REFLACTIVE)
sampler2D _Fresnel;
//sampler2D _RefractionTex;
uniform half4 _RefrColor;
#endif
#if defined (WATER_SIMPLE)
uniform half4 _HorizonColor;
uniform half4 _RefrColor;
#endif
sampler2D _BumpMap;
#if defined (WATER_EDGEBLEND_ON)
sampler2D_float _CameraDepthTexture;
//uniform fixed4 _InvFadeParemeter;
#endif

float4 frag( v2f i ) : SV_Target
{
	i.viewDir = normalize(i.viewDir);
	
	// combine two scrolling bumpmaps into one
	half3 bump1 = UnpackNormal(tex2D( _BumpMap, i.bumpuv0 )).rgb;
	half3 bump2 = UnpackNormal(tex2D( _BumpMap, i.bumpuv1 )).rgb;
	half3 bump = (bump1 + bump2) * 0.5;
	
	// fresnel factor
	half fresnelFac = dot( i.viewDir, bump );
	
	// perturb reflection/refraction UVs by bumpmap, and lookup colors
	
	#if defined(HAS_REFLECTION)
	#if HAS_REFLECTION
	half4 uv1 = i.ref; uv1.xy += bump * _ReflDistort;
	half4 refl = tex2Dproj( _ReflectionTex, UNITY_PROJ_COORD(uv1) )*1.5;
	#endif
//	#if HAS_REFRACTION
//	fixed4 uv2 = i.ref; uv2.xy -= bump * _RefrDistort;
//	fixed4 refr = tex2Dproj( _RefractionTex, UNITY_PROJ_COORD(uv2) ) * _RefrColor;
//	#endif
	#endif	
	// final color is between refracted and reflected based on fresnel	
	fixed4 color = fixed4(1,1,1,1);
	
	#if defined(WATER_REFLACTIVE)
	half fresnel = UNITY_SAMPLE_1CHANNEL( _Fresnel, half2(fresnelFac,fresnelFac) );
	half4 diffuse = lerp( fixed4(0,0,0,0), refl*_RefrColor, fresnel );
	color = half4(diffuse.rgb, lerp( 0.2, 1, fresnel*_RefrColor.a));
	//color = fixed4(1,1,0,1);
	#endif
	
//	#if defined(WATER_REFLECTIVE)
////	fixed4 water = tex2D( _ReflectiveColor, fixed2(fresnelFac,fresnelFac) );
////	color.rgb = lerp( water.rgb, refl.rgb, water.a );
////	color.a = refl.a * water.a;
//	fixed4 water = tex2D( _ReflectiveColor, fixed2(fresnelFac,fresnelFac) );
//    fixed3 diffuse = lerp( water.rgb, refl.rgb, water.a );
//	color = fixed4(diffuse.rgb, water.a );
//	//color = fixed4(1,0,0,1);
//	#endif
	
	#if defined(WATER_SIMPLE)
	half4 water = tex2D( _ReflectiveColor, half2(fresnelFac*2,fresnelFac*10));
	color.rgb = lerp( water.rgb*_RefrColor.rgb, _HorizonColor.rgb, water.a );
	color.a = _HorizonColor.a;
	//color = fixed4(0,0,1,1);
	#endif

//	fixed4 edgeBlendFactors = fixed4(1.0, 0.0, 0.0, 0.0);
		
//	#if defined(HAS_REFLECTION) || defined(HAS_REFRACTION)
//		#if defined(WATER_EDGEBLEND_ON)
//			fixed depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, (i.ref));
//			depth = LinearEyeDepth(depth);
//			edgeBlendFactors = saturate(_InvFadeParemeter * (depth-i.ref.w));		
//			edgeBlendFactors.y = 1.0-edgeBlendFactors.y;		
//			color.a = edgeBlendFactors.x;	
//		#endif	
//	#endif
	UNITY_APPLY_FOG(i.fogCoord+_FogPower, color);	
	return color;
}
ENDCG

	}
}

}
