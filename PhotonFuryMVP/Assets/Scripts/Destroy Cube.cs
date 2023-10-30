using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Karl.Project
{
    public class DestroyCube : MonoBehaviour
    {
        [SerializeField] private GameObject _targetObject;

        private Collider _collider;
        // Start is called before the first frame update
        void Start()
        {
            _collider = GetComponent<Collider>();
        }

        // Update is called once per frame
        void Update()
        {
            
        }

        private void OnCollisionEnter(Collision other)
        {
            if (other.gameObject.name == _targetObject.name)
            {
                Debug.Log("Do something here");
                _targetObject.SetActive(false);
            }
        }
    }
}

