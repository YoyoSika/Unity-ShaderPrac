Shader "ShaderPrac/Chapter6-DiffuseVertexLevel" {
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
				fixed3 color : COLOR;
			};
			
			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex.xyz);  

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 normal_world = normalize( UnityObjectToWorldNormal(v.normal));

				//_WorldSpaceLightPos0 在一个平行光源的时候才有效，其他情况以后学   
				fixed3 worldLight  = normalize(_WorldSpaceLightPos0.xyz);
				fixed diffuseStrenth  = saturate(dot(normal_world,worldLight));
				fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * diffuseStrenth;
				o.color = ambient + diffuse;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				return fixed4 (i.color,1.0);
			}


			ENDCG
		
		}

	}
	FallBack "Diffuse"
}
