﻿Shader "ShaderPrac/Chapter7-SingleTexture" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8,256)) = 20
	}
	SubShader{
	Pass
	{
		Tags{ "LightMode" = "ForwardBase" }
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "Lighting.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;//这个变量用来声明这个纹理的属性，表示scale和transform 
		fixed4 _Specular;
		float _Gloss;

		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
		};


		struct v2f {
			float4 pos : SV_POSITION;
			float3 worldNormal : TEXCOORD0;
			float3 worldPos :TEXCOORD1;
			float2 uv: TEXCOORD2;
		};

		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldNormal = UnityObjectToWorldNormal(v.normal);
			o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
			o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
			//Unity的函数为 TRANSFORM_TEX(v.texcoord,_MainTex);     
			return o;
		}

		fixed4 frag(v2f i) : SV_Target{
			fixed4 ambient = unity_AmbientSky;
			i.worldNormal = normalize(i.worldNormal);
			fixed3 lightDir =normalize(UnityWorldSpaceLightDir(i.worldPos));

			float diffuseStrenth = saturate(dot(i.worldNormal, lightDir));
			fixed4 albedo = tex2D(_MainTex, i.uv);//直接拿贴图的颜色
			fixed3 diffuse = albedo * _LightColor0 * diffuseStrenth * 0.9 + albedo *0.1;

			float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
			fixed3 halfDir = normalize(viewDir + lightDir);
			float specularStrenth = saturate(dot(halfDir, i.worldNormal));
			fixed3 specular = _Specular.rgb * specularStrenth* _LightColor0 * pow(specularStrenth,_Gloss);

			fixed3 color = ambient.xyz + diffuse + specular;
			return fixed4(color,1);
		}


		ENDCG
		}

	}
	FallBack "Diffuse"
}
