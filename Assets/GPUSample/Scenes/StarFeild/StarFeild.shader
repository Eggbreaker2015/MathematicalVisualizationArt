Shader "MathematicalVisualizationArt/StarFeild"
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
            
            //产生0-1的随机数
            float rand(float2 co)
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }
            
            //输入角度，返回旋转矩阵
            float2x2 rotate2d(float angle)
            {
                float c = cos(angle);
                float s = sin(angle);
                return float2x2(c, -s, s, c);
            }

            float Star(float2 uv, float flare)
            {
                float d = length(uv);
                float m = 0.04/d;
                
                float rays = max(0, 1 - abs(uv.x * uv.y * 10000));
                m += rays * flare * 0.1;

                uv = mul(uv, rotate2d(PI/4));
                rays = max(0, 1 - abs(uv.x * uv.y * 10000));
                m += rays * 0.1 * flare;
                m *= smoothstep(1, 0.2, d); //除去远处的值
                return m;
            }

            float3 StarLayer(float2 uv)
            {
                float3 c = 0;
                
                float2 gv = frac(uv) - 0.5;
                float2 id = floor(uv);

                for (int x = -1; x <= 1; x++)
                {
                    for (int y = -1; y <= 1; y++)
                    {
                        float2 offs = float2(x, y);
                        float n = rand(id + offs);
                        float size = frac(n * 345.32);
                        float star = Star(gv - offs - float2(n - 0.5, frac(n*10) - 0.5), smoothstep(0.9,1,size));
                        float3 color = sin(float3(0.2, 0.3, 0.9)*frac(n * 123.4)*123)*0.5 + 0.5;
                        color = color * float3(1,0.25,1);
                        star *= sin(time.x *2 + n * 2 *PI) *0.5 +1;
                        c += star * size * color;
                    }
                }

                return c;
            }
            
            
            half3 PixelColor(float2 uv)
            {
                half3 c = half3(0, 0, 0);
                //四象限转一象限
                uv.y = 1.0- uv.y;
                //全象限
                uv = uv*2.0 -1.0;
                // uv 不遂屏幕横纵比改变
                uv.x *= w/h;

                uv *= 0.5;
                //uv = mul(uv, rotate2d(time.x/20));
                uv -= sin(time.x/20); //添加镜头移动感
                int layers = 6;
                for (int i = 0; i < layers; i++)
                {
                    float process = i / (float)layers;
                    float depth = frac(process + time.x / 20.0);
                    float scale = lerp(20, 0.5, depth);
                    float fade = depth * smoothstep(1,0.98,depth);//fadein and fadeout
                    c += StarLayer(uv * scale + process * 551.2) * fade;
                }
                
                half4 finnalColor = half4(c, 1);
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
