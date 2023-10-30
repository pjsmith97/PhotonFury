using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

public class RotationController : MonoBehaviour
{
    private Vector3 _input;
    private Quaternion _rotation;
    private Rigidbody _targetRigidbody;
    
    // Start is called before the first frame update
    void Start()
    {
        _targetRigidbody = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
       GetInput();
       ApplyRotation();
    }
    private void FixedUpdate()
    {
        
    }

    void GetInput()
    {
        _input = new Vector3(Input.GetAxis("Vertical"), 0, (Input.GetAxis("Horizontal")*-1));
    }

    void ApplyRotation()
    {
        _rotation.eulerAngles = _input*5f;
        _targetRigidbody.MoveRotation(_rotation);
    }
}
