Shader "ShaderPrac/Chapter9-Shadow" {
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
			#include"AutoLight.cginc"
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
				//SV_POSITION system value postion 一旦作为vertex shader里面的输出语义，之后就不能再变化了，
				//比如做frag Shader的顶点偏移  比如Tessellation
				fixed3 worldPos : TEXCOORD0;
				fixed3 normal : TEXCOORD1;
				SHADOW_COORDS(2)
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f a) : SV_Target{
			
				fixed4 ambient = UNITY_LIGHTMODEL_AMBIENT;

				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(a.worldPos));  //_WorldSpaceLightPos0.xyz);
				fixed diffuseStrenth = saturate(dot(worldLight,a.normal));
				fixed4 diffuse = _Diffuse *_LightColor0 * diffuseStrenth;
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(a.worldPos));

				fixed3 halfDir = normalize(viewDir + worldLight);

				fixed3 specularStrenth = saturate(dot (a.normal,halfDir));
				fixed3 specular = _Specular.xyz * _LightColor0 * pow(specularStrenth,_Gloss);

				//fixed shadow = SHADOW_ATTENUATION(a);
				UNITY_LIGHT_ATTENUATION(atten, a,a.worldPos);

				fixed3 color = atten * ( specular + diffuse.xyz )+ ambient.xyz;
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
					fixed3 viewDir : TEXCOORD0;
					fixed3 normal : TEXCOORD1;
					float4 worldPos : TEXCOORD2;
				};

				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.normal = normalize(UnityObjectToWorldNormal(v.normal));
					o.viewDir = normalize(UnityWorldSpaceViewDir(mul(UNITY_MATRIX_M,v.vertex)));
					o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target{
					fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));  //Unity帮忙处理了光源类型不同的情况
					fixed diffuseStrenth = saturate(dot(worldLight,i.normal));
					fixed4 diffuse = _Diffuse * _LightColor0 * diffuseStrenth;

					fixed3 halfDir = normalize(i.viewDir + worldLight);

					fixed3 specularStrenth = saturate(dot(i.normal,halfDir));
					fixed3 specular = _Specular.xyz * _LightColor0 * pow(specularStrenth,_Gloss);
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
