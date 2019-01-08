Shader "ShaderPrac/Chapter10-Reflection" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_ReflectColor("ReflectColor", Color) = (1,1,1,1)
		_ReflectAmount("Reflect Amount",Range(0,1)) = 1
		_Cubemap("Reflection Cubemap",Cube) = "_Skybox"{}
	}
		SubShader{
		Pass{


			Tags { "RenderType" = "Opaque" }


			CGPROGRAM

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#pragma vertex vert
		#pragma fragment frag
		#include "Lighting.cginc"
		#include"AutoLight.cginc"
		samplerCUBE _Cubemap;
		fixed4 _Color;
		fixed4 _ReflectColor;
		float _ReflectAmount;
		struct a2v {
			fixed3 vertex : POSITION;
			fixed3 normal : NORMAL;
		};
		struct v2f {
			float4 pos : SV_Position;
			fixed3 worldRefl : TEXCOORD0;
			fixed3 worldViewDir : TEXCOORD1;
			fixed3 worldPos : TEXCOORD2;
			SHADOW_COORDS(3)
			fixed3 worldNormal : TEXCOORD4;
		};
		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
			o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
			o.worldNormal = UnityObjectToWorldNormal(v.normal);
			o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);
			TRANSFER_SHADOW(o);
			return o;
		}

		fixed4 frag(v2f i) :SV_Target{
			fixed3 worldNormal = normalize(i.worldNormal);
			fixed3 worldViewDir = normalize(i.worldViewDir);
			fixed3 worldRefl = normalize(i.worldRefl);
			fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

			fixed4 ambient = unity_AmbientSky;
			fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldLightDir, worldNormal));

			fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;

			UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

			fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;
			return fixed4(color, 1);
		}

		ENDCG
	}
	}
		FallBack "Diffuse"
}
