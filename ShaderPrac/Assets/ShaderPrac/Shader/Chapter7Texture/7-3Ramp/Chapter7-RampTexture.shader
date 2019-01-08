Shader "ShaderPrac/Chapter7-RampTexture" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Main", 2D) = "white" {}
		_RampTex("Ramp", 2D) = "white" {}
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
		sampler2D _RampTex;
		float4 _RampTex_ST;//这个变量用来声明这个纹理的属性，表示scale和transform
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
			float4 uv: TEXCOORD2;
		};

		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldNormal = UnityObjectToWorldNormal(v.normal);
			o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
			o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
			o.uv.zw = v.texcoord.xy * _RampTex_ST.xy + _RampTex_ST.zw;
			return o;
		}

		fixed4 frag(v2f i) : SV_Target{
			fixed4 ambient = unity_AmbientSky;
			i.worldNormal = normalize(i.worldNormal);
			fixed3 lightDir =normalize(UnityWorldSpaceLightDir(i.worldPos));

			float diffuseStrenth = saturate(dot(i.worldNormal, lightDir)) * 0.8 + 0.2;
			fixed4 albedo = tex2D(_MainTex, i.uv.xy);//直接拿贴图的颜色
			fixed4 ramp = tex2D(_RampTex,fixed2(diffuseStrenth, diffuseStrenth));
			fixed3 diffuse = _Color *  ramp * albedo * _LightColor0;

			float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
			fixed3 halfDir = normalize(viewDir + lightDir);
			float specularStrenth = saturate(dot(halfDir, i.worldNormal));
			fixed3 specular = _Specular.rgb * specularStrenth* _LightColor0 * pow(specularStrenth,_Gloss) * 0.6;

			fixed3 color = ambient.xyz + diffuse + specular;
			return fixed4(color,1);
		}


		ENDCG
		}

	}
	FallBack "Diffuse"
}
