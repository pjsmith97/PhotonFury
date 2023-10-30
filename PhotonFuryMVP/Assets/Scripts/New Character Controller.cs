using System;
using System.Collections;
using System.Collections.Generic;
using photonfury.health;
using UnityEngine;

//namespace Karl.Movement
//{
    public class NewCharacterController : MonoBehaviour
    {
        [SerializeField] private float _walkspeed = 5f;
        [SerializeField] private float _jumpforce = 15f;
        [SerializeField] private float _dashforce = 5f;
        private Rigidbody _rigidbody;

        private Vector3 PlayerMovementInput;
        //private bool isDed;

        private void Start()
        {
            _rigidbody = GetComponent<Rigidbody>();
            //isDed = false;
        }

        private void Update()
        {
            GetPlayerInput();
            if (!this.GetComponent<PlayerHealth>().AreUDed())
            {
                MovePlayer();
            }
        }

        private void FixedUpdate()
        {
            
        }

        void GetPlayerInput()
        {
            PlayerMovementInput = new Vector3(Input.GetAxis("Horizontal"), 0f, Input.GetAxis("Vertical"));
        }

        void MovePlayer()
        {
            Vector3 MoveVector = transform.TransformDirection(PlayerMovementInput) * _walkspeed;
            MoveVector = Quaternion.Euler(0, 45, 0) * MoveVector;
            _rigidbody.velocity = new Vector3(MoveVector.x, _rigidbody.velocity.y, MoveVector.z);
            //Quaternion targetRotation = Quaternion.LookRotation(MoveVector);

            if (Input.GetKeyDown(KeyCode.Space))
            {
                _rigidbody.AddForce(Vector3.up * _jumpforce, ForceMode.Impulse);
            }

            if (Input.GetKeyDown(KeyCode.D))
            {
                _rigidbody.AddForce(MoveVector * _dashforce, ForceMode.Impulse);
            }
        }

        //public void Death()
        //{
        //    isDed = true;
        //    this.transform.GetChild(2).gameObject.SetActive(false);
        //}
        
        
    }
//}

