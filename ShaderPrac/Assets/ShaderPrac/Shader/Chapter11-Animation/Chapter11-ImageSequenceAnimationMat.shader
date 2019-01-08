Shader "ShaderPrac/Chapter11-ImageSequenceAnimationMat" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_HorizontalAmount("Horizontal Amount",float) = 4//水平和竖直方向帧的个数
		_VerticalAmount("Vertical Amount",float) = 4
		_Speed("Speed",Range(1,100)) = 30
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "IgnoreProjectors" = "true""Queue" = "Transparent"}

		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "Lighting.cginc"


		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed4 _Color;
		float _HorizontalAmount;
		float _VerticalAmount;
		float _Speed;

		struct a2v {
			fixed3 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
		};
		struct v2f {
			float4 pos:SV_POSITION;
			float2 uv : TEXCOORD0;
		};
		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
			return o;
		}

		fixed4 frag(v2f i) :SV_Target {
			float time = floor(_Time.y * _Speed);
			float row = floor(time / _HorizontalAmount);
			float column = time - row * _HorizontalAmount;

			half2 uv = half2(i.uv.x / _HorizontalAmount, i.uv.y / _VerticalAmount);
			uv.x += column / _VerticalAmount;
			uv.y -= row / _HorizontalAmount;//纹理是从上往下移动，UV是从左下到右上，二者相反

			fixed4 c = tex2D(_MainTex, uv);
			c.rgb *= _Color;
			return c;
		}



		ENDCG
		}
	}
			FallBack "Transparent/VertexLit"
}
