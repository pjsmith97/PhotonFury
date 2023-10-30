using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Karl.Movement {
    public class CharacterMovement : MonoBehaviour {

        private CharacterController _characterController;
        private Rigidbody _rigidbody;
        private Vector3 _characterVelocity;
        [SerializeField] private float _walkspeed = 500f;
        private bool isGrounded;
        private bool jumpPressed;
        private bool dashPressed;
        
        // Start is called before the first frame update
        void Start() {
            _characterController = GetComponent<UnityEngine.CharacterController>();
            Debug.Log("Got Character Controller");
        }

        // Update is called once per frame
        void Update() {
            MoveCharacter();
            JumpCharacter();
            _characterController.Move(_characterVelocity * Time.deltaTime);
            isGrounded = _characterController.isGrounded;
            jumpPressed = Input.GetKeyDown(KeyCode.Space);
            Debug.Log(_characterVelocity.y);
        }

        public void MoveCharacter() {
            Vector3 move = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical"));
            move = Quaternion.Euler(0, 45, 0) * move;
            _characterVelocity.x = move.x * _walkspeed;
            _characterVelocity.z = move.z * _walkspeed;
        }

        public void JumpCharacter() {
            if (isGrounded && jumpPressed) {
                Vector3 jump = new Vector3(0, 1000, 0);
                _characterVelocity.y = jump.y * Time.deltaTime;
                Debug.Log("Jumped");
            } else if (isGrounded && !jumpPressed) {
                _characterVelocity.y = -0.1f * Time.deltaTime;
                Debug.Log("Grounded");
            }
            else if (!isGrounded) {
                Vector3 gravity = new Vector3(0, -9.81f, 0);
                _characterVelocity.y += gravity.y * Time.deltaTime;
            }
        }
    }
}

