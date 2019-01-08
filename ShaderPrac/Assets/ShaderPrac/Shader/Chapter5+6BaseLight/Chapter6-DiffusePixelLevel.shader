Shader "ShaderPrac/Chapter6-DiffusePixelLevel" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1,1,1,1)
	}
	SubShader {
		Pass{
		Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Diffuse;
			 
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;//从vert shader 到 frag shader 的途中normal 的插值？
			};
			
			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex.xyz);  
				fixed3 normal_world = normalize( UnityObjectToWorldNormal(v.normal));
				o.worldNormal = normal_world;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				//_WorldSpaceLightPos0 在一个平行光源的时候才有效，其他情况以后学      
				fixed3 worldLight  = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldNomal  = normalize(i.worldNormal);
				fixed diffuseStrenth  = saturate(dot(worldNomal,worldLight));
				fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * diffuseStrenth;
				fixed4 color = fixed4((ambient + diffuse),1);
				return color;
			}


			ENDCG
		
		}

	}
	FallBack "Diffuse"
}
