using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetection : PostEffectsBase
{
    [Range(0.0f, 1.0f)]
    public float edgeOnly = 0.0f;

    public Color edgeColor = Color.black;

    public Color backGroundColor = Color.white;


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null) {
            material.SetFloat("_EdgeOnly", edgeOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backGroundColor);

            Graphics.Blit(source, destination,material);
        } else {
            Graphics.Blit(source, destination);
            print("mat null");
        }
    }

}
