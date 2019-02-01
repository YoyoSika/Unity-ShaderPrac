using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase
{
    [Range(0.0f, 0.9f)]
    public float blurAmount = 0.5f;//这个作为alpha，原有影响会在不断的blend过程中，逐步消隐

    private RenderTexture accumTex;//用能够缓存下来的RT 而不是临时RT 

    private void OnDisable()
    {
        DestroyImmediate(accumTex); 
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (accumTex == null || accumTex.width != source.width || accumTex.height != source.height) {
            DestroyImmediate(accumTex);
            accumTex = new RenderTexture(source.width, source.height, 0);
            accumTex.hideFlags = HideFlags.HideAndDontSave;
            Graphics.Blit(source, accumTex);
        }

        accumTex.MarkRestoreExpected();//这张贴图不会discard之后再渲染，而是逐层叠加，用这个关掉Unity警告

        material.SetFloat("_BlurAmount", 1 - blurAmount);

        Graphics.Blit(source, accumTex, material);
        Graphics.Blit(accumTex, destination);
    }

}

