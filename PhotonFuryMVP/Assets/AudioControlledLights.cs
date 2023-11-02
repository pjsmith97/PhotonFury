using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using AudioLink;

public class AudioControlledLights : MonoBehaviour
{
    private Light _light;

    [SerializeField] private AudioLink.AudioLink _audioLink;
    // Start is called before the first frame update
    void Start()
    {
        _light = GetComponent<Light>();
    }

    // Update is called once per frame
    void Update()
    {
        Vector4 thing = _audioLink.LerpAudioDataAtPixel(0,0);
        //Debug.Log(thing);
        _light.intensity = thing.x * 2.5f;
    }
}
