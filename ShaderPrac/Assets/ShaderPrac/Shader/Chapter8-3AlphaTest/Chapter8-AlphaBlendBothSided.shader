Shader "ShaderPrac/Chapter8-AlphaBlendBothSided" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_AlphaScale("Alpha Scale",Range(0,1)) = 0.5
	}
	SubShader{
	Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
	Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			
			ZWrite Off
			Cull Front //需要保证半透明物体的从远到近的渲染顺序
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "Lighting.cginc"

			fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;//这个变量用来声明这个纹理的属性，表示scale和transform 
		float _AlphaScale;

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

		fixed4 albedo = tex2D(_MainTex, i.uv) * fixed4(_Color.rgb,1);

		i.worldNormal = normalize(i.worldNormal);
		fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
		float diffuseStrenth = saturate(dot(i.worldNormal, lightDir));
		fixed4 diffuse = albedo * _LightColor0 * diffuseStrenth * 0.9 + albedo * 0.1;
		fixed4 color = fixed4(ambient.xyz + diffuse.xyz, diffuse.a);
		color.a *= _AlphaScale;
		return color;
		}


			ENDCG
		}

	Pass
	{
		Tags{ "LightMode" = "ForwardBase"}

		ZWrite Off
		Cull Back //需要保证半透明物体的从远到近的渲染顺序
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "Lighting.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;//这个变量用来声明这个纹理的属性，表示scale和transform 
		float _AlphaScale;

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

			fixed4 albedo = tex2D(_MainTex, i.uv) * fixed4(_Color.rgb,1);

			i.worldNormal = normalize(i.worldNormal);
			fixed3 lightDir =normalize(UnityWorldSpaceLightDir(i.worldPos));
			float diffuseStrenth = saturate(dot(i.worldNormal, lightDir));
			fixed4 diffuse = albedo * _LightColor0 * diffuseStrenth * 0.9 + albedo *0.1;
			fixed4 color = fixed4(ambient.xyz + diffuse.xyz, diffuse.a);
			color.a *= _AlphaScale;
			return color;
		}


		ENDCG
		}

	}
	FallBack "Transparent/VertexLit"
}
