Shader "ShaderPrac/Chapter10-GlassRefraction" {
	Properties{
		_MainTex("Main Tex",2D) = "white"{}
		_RefractAmount("Refract Amount",Range(0,1)) = 1
		_Cubemap("Refraction Cubemap",Cube) = "_Skybox"{}
		_BumpMap("Normal Map",2D) = "bump"{}
		_Distortion("Distortion",Range(0,100)) = 10
		_RefractRatio("RefractRatio",Range(0.1,1)) = 0.5
	}
		SubShader{
			Tags{ "RenderType" = "Opaque" "Queue" = "Transparent" "LightMode" = "ForwardBase"}
			GrabPass{"_RefractionTex"}
		Pass{
		CGPROGRAM
	#pragma target 3.0
	#pragma vertex vert
	#pragma fragment frag
	#include "Lighting.cginc"
	#include"AutoLight.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		samplerCUBE _Cubemap;
		sampler2D _RefractionTex;
		float4 _RefractionTex_TexelSize;//纹素大小，每一个像素的大小

		float _RefractAmount;
		float _RefractRatio;
		float _Distortion;


		struct a2v {
			fixed3 vertex : POSITION;
			fixed3 normal : NORMAL;
			fixed4 tangent : TANGENT;
			float4 texcoord : TEXCOORD0;
		};
		struct v2f {
			float4 pos : SV_Position;
			float4 uv : TEXCOORD0;
			float4 scrPos : TEXCOORD1;
			float4 TtoW0 : TEXCOORD2;
			float4 TtoW1 : TEXCOORD3;
			float4 TtoW2 : TEXCOORD4;
		};
		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.scrPos = ComputeGrabScreenPos(o.pos);//计算屏幕坐标
			o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

			float3 worldPos = mul(UNITY_MATRIX_M, v.vertex);
			float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			float3 worldTan = UnityObjectToWorldDir(v.tangent.xyz);
			float3 worldBinormal = cross(worldTan, worldNormal) * v.tangent.w;

			o.TtoW0 = float4(worldTan.x, worldBinormal.x, worldNormal.x, worldPos.x);
			o.TtoW1 = float4(worldTan.y, worldBinormal.y, worldNormal.y, worldPos.y);
			o.TtoW2 = float4(worldTan.z, worldBinormal.z, worldNormal.z, worldPos.z);

			return o;
		}

		fixed4 frag(v2f i) :SV_Target{
			fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
			fixed3 unpackedNormal = UnpackNormal(packedNormal);

			//计算扰动--对屏幕坐标进行扰动
			float2 offset = unpackedNormal.xy * _Distortion  * _RefractionTex_TexelSize.xy;
			i.scrPos.xy += offset;
			//拿到透过来的颜色，也就是折射颜色
			fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;//_RefractionTex是grab下来的,这里做透视除法转换为了(0,1)的uv坐标



			fixed3 worldNormal = fixed3(mul(unpackedNormal, i.TtoW0), mul(unpackedNormal, i.TtoW1), mul(unpackedNormal, i.TtoW2));
			worldNormal = normalize(worldNormal);
			float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
			fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

			//如果是拿CubeMap的颜色作为折射颜色,则无法看到后面的物体，只能看到CubeMap里面的信息，而Grab的pass可以看到后面东西
			//fixed3 refraDir = refract(-worldViewDir, worldNormal, _RefractRatio);
			//refrCol = texCUBE(_Cubemap, refraDir).rgb;

			//计算反射
			fixed3 reflDir = reflect(-worldViewDir, worldNormal);
			fixed3 reflColor = texCUBE(_Cubemap, reflDir).rgb;//反射颜色
			fixed3 mainTexColor = tex2D(_MainTex, i.uv.xy);

			fixed3 finalColor = reflColor * mainTexColor  * (1 - _RefractAmount) + refrCol * _RefractAmount;
			return fixed4(finalColor, 1);
		}

			ENDCG
		}
		}
			FallBack "Diffuse"
}