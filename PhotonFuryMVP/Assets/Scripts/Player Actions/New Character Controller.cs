using System;
using System.Collections;
using System.Collections.Generic;
using photonfury.health;
using photonfury.level;
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

        [SerializeField] LevelProgressManager lvlPrgsManager;

        [Header ("Dashing")]
        public bool dashing;

        [SerializeField] Animator _dashanimator;
        [SerializeField] MeshRenderer dashShield;
        [SerializeField] TrailRenderer trail;

    //private bool isDed;

    private void Start()
        {
            _rigidbody = GetComponent<Rigidbody>();
            //isDed = false;
        }

        private void Update()
        {
            GetPlayerInput();
            if (!lvlPrgsManager.gameOver)
            {
                MovePlayer();
            }

            if (dashing)
            {
                //dashShield.enabled = true;
                trail.time = 0.5f;
            }

            else if (dashShield.enabled)
            {
                //dashShield.enabled = false;
                trail.time = 0;
            }
        }

        private void FixedUpdate()
        {
            if(_rigidbody.velocity.magnitude < 10f && dashing)
            {
                dashing = false;
                Debug.Log("Slowing...");
                _dashanimator.SetBool("isOn", dashing);
            }
        }

        void GetPlayerInput()
        {
            PlayerMovementInput = new Vector3(Input.GetAxis("Horizontal"), 0f, Input.GetAxis("Vertical"));
            PlayerMovementInput = Quaternion.Euler(0, 45, 0) * PlayerMovementInput;
        }

        void MovePlayer()
        {
            Vector3 MoveVector = transform.TransformDirection(PlayerMovementInput) * _walkspeed;
            //MoveVector = Quaternion.Euler(0, 45, 0) * MoveVector;
            _rigidbody.velocity = new Vector3(MoveVector.x, _rigidbody.velocity.y, MoveVector.z);
            //Quaternion targetRotation = Quaternion.LookRotation(MoveVector);

            if (Input.GetKeyDown(KeyCode.Space))
            {
                _rigidbody.AddForce(Vector3.up * _jumpforce, ForceMode.Impulse);
            }

            if (Input.GetKeyDown(KeyCode.D))
            {
                _rigidbody.AddForce(PlayerMovementInput * _dashforce, ForceMode.Impulse);
                dashing = true;
                Debug.Log("DASHING!");
                _dashanimator.SetBool("isOn", dashing);
            }
        }

        //public void Death()
        //{
        //    isDed = true;
        //    this.transform.GetChild(2).gameObject.SetActive(false);
        //}
        
        
    }
//}

