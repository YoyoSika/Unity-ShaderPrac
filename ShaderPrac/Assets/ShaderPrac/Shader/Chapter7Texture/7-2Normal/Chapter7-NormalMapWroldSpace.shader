Shader "ShaderPrac/Chapter7-NormalMapWroldSpace" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8,256)) = 20
		_BumpMap("Normal Map",2D) = "bump"{}//模型自带的法线对应的Unity内置的变量为“bump”
		_BumpScale("Bump Scale",Float) = 1.0
		_SpecularMax("SpecularMax",Range(0,1)) = 1.0
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
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		float _BumpScale;
		float _SpecularMax;

		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 tangent : TANGENT;
		};


		struct v2f {
			float4 pos : SV_POSITION;
			float3 worldPos :TEXCOORD0;
			float4 uv: TEXCOORD1;
			float3 TtoW1 : TEXCOORD2;
			float3 TtoW2 : TEXCOORD3;
			float3 TtoW3 : TEXCOORD4;
		};

		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap); 

			float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
			float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
			float3 worldBinormal = cross(worldNormal, normalize(worldTangent.xyz)) * v.tangent.w;

			//tangent,binormal,normal  组成 一个从tangent坐标系到世界坐标系的矩阵
			// TtoW1,TtoW2,TtoW3  dot  tanNormal =  (TtoW1 dot tanNormal,TtoW2 dot tanNormal,TtoW3 dot tanNormal)的转置
			o.TtoW1 = fixed3(worldTangent.x, worldBinormal.x, worldNormal.x);
			o.TtoW2 = fixed3(worldTangent.y, worldBinormal.y, worldNormal.y);
			o.TtoW3 = fixed3(worldTangent.z, worldBinormal.z, worldNormal.z);
			return o;
		}

		fixed4 frag(v2f i) : SV_Target{
			fixed4 ambient = unity_AmbientSky;
			float3 tanNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
			tanNormal.xy *= _BumpScale;//改偏移的程度
			tanNormal.z = sqrt(1 - dot(tanNormal.xy, tanNormal.xy));//z跟着做适应

			float3 worldNormal = normalize(fixed3(dot(tanNormal, i.TtoW1), dot(tanNormal, i.TtoW2), dot(tanNormal, i.TtoW3)));
			fixed3 lightDir =normalize(UnityWorldSpaceLightDir(i.worldPos));

			float diffuseStrenth = saturate(dot(worldNormal, lightDir));
			fixed4 albedo = tex2D(_MainTex, i.uv.xy);//直接拿贴图的颜色
			fixed3 diffuse = albedo * _LightColor0 * diffuseStrenth * 0.9 + albedo *0.1;

			float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
			fixed3 halfDir = normalize(viewDir + lightDir);
			float specularStrenth = saturate(dot(halfDir, worldNormal));
			fixed3 specular = _Specular.rgb * specularStrenth* _LightColor0 * pow(specularStrenth,_Gloss);
			specular *= _SpecularMax;

			fixed3 color = ambient.xyz + diffuse + specular;
			return fixed4(color,1);
		}


		ENDCG
		}

	}
	FallBack "Diffuse"
}
