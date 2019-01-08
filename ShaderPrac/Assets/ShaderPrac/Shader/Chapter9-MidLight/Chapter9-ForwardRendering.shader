// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

//          
Shader "ShaderPrac/Chapter9-ForwardRendering" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1,1,1,1)
		_Gloss ("Gloss", Range(8.0,256)) = 20
		_Specular("Specular",Color)= (1,1,1,1)  
	}
	SubShader {
		Pass{
			Tags { "LightMode"= "ForwardBase" }
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#pragma multi_compile_fwdbase//告诉编译器这是ForwardBase 的pass，要准备好相关光照变量(比如光照衰减)

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				fixed3 vertex : POSITION;
				fixed3 normal : NORMAL;
			};
			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 worldPos : TEXCOORD0;
				fixed3 normal : TEXCOORD1;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = mul(UNITY_MATRIX_M,v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
			
				fixed4 ambient = UNITY_LIGHTMODEL_AMBIENT;

				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));  //_WorldSpaceLightPos0.xyz);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				fixed diffuseStrenth = saturate(dot(worldLight,i.normal));
				fixed4 diffuse = _Diffuse *_LightColor0 * diffuseStrenth;

				fixed3 halfDir = normalize(viewDir + worldLight);

				fixed3 specularStrenth = saturate(dot (i.normal,halfDir));
				fixed3 specular = _Specular.xyz * _LightColor0 * pow(specularStrenth,_Gloss);
				fixed atten = 1.0;

				fixed3 color = atten* ( specular + diffuse.xyz )+ ambient.xyz;
				return fixed4(color,1);
			}

			ENDCG		
		}

		Pass
			{
				Tags{"LightMode" = "ForwardAdd"}
				Blend One One

				CGPROGRAM
				#pragma multi_compile_fwdadd
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"
				#include"AutoLight.cginc"

				fixed4 _Diffuse;
				fixed4 _Specular;
				float _Gloss;

				struct a2v {
					fixed3 vertex : POSITION;
					fixed3 normal : NORMAL;
				};
				struct v2f {
					float4 pos : SV_POSITION;
					fixed3 normal : TEXCOORD0;
					float4 worldPos : TEXCOORD1;
				};

				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.normal = normalize(UnityObjectToWorldNormal(v.normal));
					o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target{
					fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
					fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));  //Unity帮忙处理了光源类型不同的情况
					fixed3 halfDir = normalize(viewDir + worldLight);

					fixed3 specularStrenth = saturate(dot(i.normal,halfDir));
					fixed3 specular = _Specular.xyz * _LightColor0 * pow(specularStrenth,_Gloss);

					fixed diffuseStrenth = saturate(dot(worldLight, i.normal));
					fixed4 diffuse = _Diffuse * _LightColor0 * diffuseStrenth;
#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
#else
#if defined (POINT)
					float3 lightCoord = mul(unity_WorldToLight, i.worldPos).xyz;
					fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#elif defined (SPOT)
					float4 lightCoord = mul(unity_WorldToLight, i.worldPos);
					fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#else
					fixed atten = 1.0;
#endif
#endif
					fixed3 color = atten * (specular + diffuse.xyz);
					return fixed4(color,1);
				}
				ENDCG
			}
	}
	FallBack "Specular"
}
