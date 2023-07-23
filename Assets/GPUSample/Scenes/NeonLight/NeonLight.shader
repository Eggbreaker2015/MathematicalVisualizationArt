Shader "MathematicalVisualizationArt/NeonLight"
{
    Properties
    {
    }
    
    SubShader
    {
        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            Name "DefaultPass"
            
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float4 positionCS               : SV_POSITION;
                float4 screenPos                : TEXCOORD1;
            };

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.uv = input.uv;
                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
            }

            #define time _Time.y
            #define w _ScreenParams.x
            #define h _ScreenParams.y

            //调色板方程
            half3 palette(float t, half3 a, half3 b, half3 c, half3 d)
            {
                return a + b * cos(6.28318*(c*t + d));
            }

            half3 MyPalette(float t)
            {
                half3 a = half3(0.5, 0.5, 0.5);
                half3 b = half3(0.5, 0.5, 0.5);
                half3 c = half3(1.0, 1.0, 1.0);
                half3 d = half3(0.263, 0.416, 0.557);
                
                return a + b * cos(6.28318*(c*t + d));
            }
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //---编写你的逻辑, 不要超过2023个字节（包括空格）
                //四象限转一象限
                uv.y = 1.0- uv.y;
                //全象限
                uv = uv*2.0 -1.0;
                // uv 不遂屏幕横纵比改变
                uv.x *= w/h;
                half2 uv0 = uv;
                half3 finnalColor = half3(0,0,0);
                
                for(int i = 0; i < 4; i++)
                {
                    uv = frac(uv * 1.3) - 0.5;
                    c = length(uv) * exp(-length(uv0));
                    half3 col = MyPalette(length(uv0) + time.x * 0.4 + i * 0.4);
                    
                    c = sin(c * 8 + time.x)/8;
                    c = abs(c);
                    c = pow (0.01 / c, 1.2);

                    c *= col;
                    finnalColor += c;
                }
                
                
                //c = saturate(sqrt((pow(uv.y*co,2) + pow(uv.x,2))*0.5));
                //---
                return finnalColor;
            }

            half4 frag(Varyings input) : SV_Target 
            {
                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                #if UNITY_UV_STARTS_AT_TOP
                screenUV = screenUV * float2(1.0, -1.0) + float2(0.0, 1.0);
                #endif
                half3 col = Gamma22ToLinear(PixelColor(screenUV));
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
