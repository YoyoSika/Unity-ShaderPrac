Shader "ShaderPrac/Chapter10-ReflectionWithFresnel" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_RefractColor("RefractColor", Color) = (1,1,1,1)
		_Cubemap("Reflection Cubemap",Cube) = "_Skybox"{}
		_FresnelScale("FresnelScale",Range(0,1)) = 0.5
	}
		SubShader{
		Pass{
			Tags{ "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include"AutoLight.cginc"
			samplerCUBE _Cubemap;
			fixed4 _Color;
			fixed4 _RefractColor;
			float _FresnelScale;
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
				o.worldRefl = reflect(-normalize(o.worldViewDir), o.worldNormal);
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) :SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 worldRefl = normalize(i.worldRefl);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed4 ambient = unity_AmbientSky;
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

				fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _RefractColor.rgb;

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				//经验公式，实际上还是利用了  dot(worldNormal, worldViewDir) 的特点
				float fresnel = _FresnelScale + pow(1 - dot(worldNormal, worldViewDir), 5) * (1 - _FresnelScale);
				fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel))* atten;
				return fixed4(color, 1);
			}

			ENDCG
		}
		}
			FallBack "Diffuse"
}
