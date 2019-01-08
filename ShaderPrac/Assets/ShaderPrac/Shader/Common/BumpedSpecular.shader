Shader "ShaderPrac/Common/BumpedSpecular"
{
	Properties{
		_DiffuseColor("DiffuseColor",Color) = (1,1,1,1)
		_MainTex("Albedo",2D) = "white"{}
		_NormalTex("BumpTex",2D) = "bump"{}
		_BumpScale("BumpScale",float) = 1.0
		_SpecularColor("SpecularColor",Color) = (1,1,1,1)
		_SpecularStrenth("SpecularStrenth",float) = 1.0
		_SpecularGloss("SpecularGloss",float) = 10
	}
		SubShader
		{
		Pass
		{
			Tags{ "RenderType" = "Opaque" "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include"AutoLight.cginc"

			fixed4 _DiffuseColor;
			fixed4 _SpecularColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalTex;
			float _BumpScale;
			float _SpecularStrenth;
			float _SpecularGloss;

			struct a2v {
				fixed3 vertex : POSITION;
				fixed3 normal : NORMAL;
				fixed4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			struct v2f {
				float4 pos : SV_Position;
				fixed3 worldPos : TEXCOORD0;
				fixed3 t2w0 : TEXCOORD1;
				fixed3 t2w1 : TEXCOORD2;
				fixed3 t2w2 : TEXCOORD3;
				float2 uv : TEXCOORD4;
				SHADOW_COORDS(5)
			};
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				TRANSFER_SHADOW(o);

				//tangentSpace (tangent,bnormal, normal)
				fixed3 worldTangent = normalize(mul(UNITY_MATRIX_M, v.tangent.xyz));
				fixed3 worldNormal = normalize(mul(UNITY_MATRIX_M, v.normal));
				fixed3 worldBinormal = normalize(cross(worldTangent, worldNormal)*v.tangent.w);

				o.t2w0 = fixed3(worldTangent.x, worldBinormal.x, worldNormal.x);
				o.t2w1 = fixed3(worldTangent.y, worldBinormal.y, worldNormal.y);
				o.t2w2 = fixed3(worldTangent.z, worldBinormal.z, worldNormal.z);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				//diffuse
				fixed4 packedNormal = tex2D(_NormalTex,i.uv);
				fixed3 tanNormal = normalize(UnpackNormal(packedNormal));
				tanNormal.xy = _BumpScale * tanNormal.xy;
				tanNormal.z = sqrt(1 - dot(tanNormal.xy, tanNormal.xy));
				//注意得在tangent坐标系做这个bumpscale，如果去世界坐标系bumpscale，是错误的
				fixed3 worldNormal = normalize(fixed3(mul(i.t2w0, tanNormal), mul(i.t2w1, tanNormal), mul(i.t2w2, tanNormal)));


				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));

				float strenth = max(0,dot(worldLight, worldNormal)) ;//别全黑
				fixed4 albedo = tex2D(_MainTex, i.uv) * strenth * _DiffuseColor * _LightColor0;

				//specular
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(viewDir + worldLight);
				strenth = pow(saturate(dot(worldNormal, halfDir)), _SpecularGloss);
				fixed4 specular = strenth * _LightColor0 * _SpecularStrenth * _SpecularColor;

				//ambient 
				fixed4 ambient = unity_AmbientSky;
				//atten and shadow
				UNITY_LIGHT_ATTENUATION(atten,i, i.worldPos);

				fixed4 color = ambient + atten * (specular + albedo);

				return color;
				}
				ENDCG
			}

		}
			FallBack "Specular"
}
