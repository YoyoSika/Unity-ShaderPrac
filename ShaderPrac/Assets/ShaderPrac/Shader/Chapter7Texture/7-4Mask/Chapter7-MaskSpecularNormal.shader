Shader "ShaderPrac/Chapter7-MaskSpecularNormal" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map",2D) = "bump"{}//模型自带的法线对应的Unity内置的变量为“bump”
		_BumpScale("Bump Scale",Float) = 1.0
		_MaskTex("Mask Map", 2D) = "white" {}
		_SpecularScale("SpecularScale",Range(0,1)) = 1.0
		_Specular("Specular",Color) = (1,1,1,1)
		_SpecularMax("SpecularMax",Range(0,1)) = 1.0
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
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		float _BumpScale;
		fixed4 _Specular;
		float _Gloss;
		float _SpecularMax;
		sampler2D _MaskTex;
		float _SpecularScale;

		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 tangent : TANGENT;
		};


		struct v2f {
			float4 pos : SV_POSITION;
			float4 uv: TEXCOORD0;
			float3 lightDir : TEXCOORD1;//tangentSpace
			float3 viewDir : TEXCOORD2;//tangentSpace
		};

		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			//TANGENT_SPACE_ROTATION 
			TANGENT_SPACE_ROTATION;
			o.lightDir = normalize(mul(rotation,ObjSpaceLightDir(v.vertex)));

			o.viewDir = normalize(mul(rotation, ObjSpaceViewDir(v.vertex)));

			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
			//Unity的函数为 TRANSFORM_TEX(v.texcoord,_MainTex);     
			return o;
		}

		fixed4 frag(v2f i) : SV_Target{
			
			float3 normalTan = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
			normalTan.xy *= _BumpScale;//改偏移的程度
			normalTan.z = sqrt(1-dot(normalTan.xy, normalTan.xy));//z跟着做适应

			fixed4 ambient = unity_AmbientSky;
			fixed3 lightDir =normalize(i.lightDir);
			fixed3 viewDir = normalize(i.viewDir);


			float diffuseStrenth = saturate(dot(normalTan, lightDir));
			fixed4 albedo = tex2D(_MainTex, i.uv.xy);//直接拿贴图的颜色
			fixed3 diffuse = albedo * _LightColor0 * diffuseStrenth * 0.9 + albedo *0.1;

			fixed3 halfDir = normalize(viewDir + lightDir);
			float specularStrenth = saturate(dot(halfDir, normalTan));
			float specularMask = tex2D(_MaskTex, i.uv.xy).r * _SpecularScale;
			fixed3 specular = _Specular.rgb * specularStrenth * specularMask * _LightColor0 * pow(specularStrenth,_Gloss);
			specular *= _SpecularMax;

			fixed3 color = ambient.xyz + diffuse + specular;
			return fixed4(color,1);
		}


		ENDCG
		}

	}
	FallBack "Diffuse"
}
