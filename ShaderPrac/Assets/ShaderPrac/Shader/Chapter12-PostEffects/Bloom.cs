﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectsBase
{
    [Range(0, 4)]
    public int iterations = 3;

    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    [Range(1, 8)]
    public int downSample = 2;

    [Range(0f, 4.0f)]
    public float luminanceThreshold = 0.6f;
    /// <summary>
    /// bloom原理：
    /// 把超过阈值的高亮度区域 blur一下 再和原来的图像混合
    /// </summary>
    /// <param name="source"></param>
    /// <param name="destination"></param>
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null) {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
            int rtW = source.width ;
            int rtH = source.height ;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            Graphics.Blit(source, buffer0,material,0);
            //模糊的迭代次数
            for (int i = 0; i < iterations; i++) {
                //需要两个buffer来缓存迭代模糊的中间量
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 1);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;

                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 2);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            material.SetTexture("_Bloom", buffer0);
            Graphics.Blit(source, destination,material,3);
            RenderTexture.ReleaseTemporary(buffer0);
        }
    }

}
