//          
Shader "ShaderPrac/Chapter6-SpecularVetexlLevel" {
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
				fixed3 color : COLOR;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				fixed4 ambient = UNITY_LIGHTMODEL_AMBIENT;

				fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				fixed diffuseStrenth = saturate(dot(worldLight,worldNormal));
				fixed4 diffuse = _Diffuse *_LightColor0 * diffuseStrenth;

				fixed3 lightReflectDir = normalize(reflect(-worldLight,worldNormal));
				fixed3 viewDir = normalize(_WorldSpaceCameraPos - mul(UNITY_MATRIX_M,v.vertex));
				fixed3 specularStrenth = saturate(dot (viewDir,lightReflectDir));
			
				fixed3 specular = _Specular.xyz * _LightColor0 * pow(specularStrenth,_Gloss);
			 
				o.color =specular + diffuse.xyz + ambient.xyz;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				return fixed4(i.color,1);
			}

			ENDCG		
		}
	}
	FallBack "Diffuse"
}
