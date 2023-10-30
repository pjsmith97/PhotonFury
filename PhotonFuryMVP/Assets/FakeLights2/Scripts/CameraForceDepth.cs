using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraForceDepth : MonoBehaviour {

    public DepthTextureMode depthTextureMode;
    [SerializeField,HideInInspector] private Camera thisCamera;

    private void Awake()
    {
        SetDepthTextureMode();
    }


    [ContextMenu("Set Depth Texture Mode")]
    void SetDepthTextureMode()
    {
        if(thisCamera == null)
            thisCamera = GetComponent<Camera>();

        if (thisCamera == null)
            return;

        if (thisCamera.depthTextureMode != depthTextureMode)
        {
            thisCamera.depthTextureMode = depthTextureMode;
            Debug.Log("Depth Texture Mode = " + thisCamera.depthTextureMode);
        }
    }

    private void OnValidate()
    {
        SetDepthTextureMode();
    }
}
