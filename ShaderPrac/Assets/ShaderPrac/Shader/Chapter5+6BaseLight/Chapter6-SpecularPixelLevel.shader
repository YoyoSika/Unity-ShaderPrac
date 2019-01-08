//          
Shader "ShaderPrac/Chapter6-SpecularPixelLevel" {
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

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				fixed3 vertex : POSITION;
				fixed3 normal : NORMAL;
			};
			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 viewDir : TEXCOORD0;
				fixed3 normal : TEXCOORD1;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normal = normalize(UnityObjectToWorldNormal(v.normal));
				o.viewDir = normalize(_WorldSpaceCameraPos - mul(UNITY_MATRIX_M,v.vertex));	 
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
			
				fixed4 ambient = UNITY_LIGHTMODEL_AMBIENT;

				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				fixed diffuseStrenth = saturate(dot(worldLight,i.normal));
				fixed4 diffuse = _Diffuse *_LightColor0 * diffuseStrenth;

				fixed3 lightReflectDir = normalize(reflect(-worldLight,i.normal));
				fixed3 specularStrenth = saturate(dot (i.viewDir,lightReflectDir));
				fixed3 specular = _Specular.xyz * _LightColor0 * pow(specularStrenth,_Gloss);

				fixed3 color = specular + diffuse.xyz + ambient.xyz;
				return fixed4(color,1);
			}

			ENDCG		
		}
	}
	FallBack "Diffuse"
}
