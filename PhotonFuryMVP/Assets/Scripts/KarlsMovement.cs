using System;
using System.Numerics;
using UnityEngine;
using UnityEngine.EventSystems;
using Quaternion = UnityEngine.Quaternion;
using Vector3 = UnityEngine.Vector3;

namespace Karl.Movement.YesPhillipNoticeMyNameSpace {
    public class KarlsMovement : MonoBehaviour {
        private Rigidbody _rigidbody;
        
        [Header("Movement Parameters")]
        [SerializeField] private float walkspeed = 5;
        [SerializeField] private float dashmultiplier = 2;
        
        [Header("PlayerInput")]
        private Vector3 _playerInputVector;
        private float _playerInputAngleOffset = 225;
        
        [Header("PlayerMovement")]
        private Vector3 _playerMovementVector;
        
        [Header("Jumping")]
        [SerializeField] private float jumpvelocity = 5;
        [SerializeField] private float _jumpcoolduration = 1;
        [SerializeField] private LayerMask groundMask;
        [SerializeField] private float _playerHeight = 2;
        private bool _jumping = false;
        private bool _ableToJump = true;
        private bool _jumpcooling = false;
        private float _jumpcooltimer;
        private bool _isGrounded;
        
        [Header("Dashing")]
        [SerializeField] private float _dashduration = 1;
        [SerializeField] private float _dashcoolduration = 2;
        private bool _dashing = false;
        private bool _ableToDash = true;
        private float _dashtimer;
        private bool _dashcooling = false;
        private float _dashcooltimer;

        [Header("Slope Handling")]
        [SerializeField] private float maxSlopeAngle = 45;
        private RaycastHit slopeHit;
        
        // Start is called before the first frame update
        void Start() {
            _rigidbody = GetComponent<Rigidbody>();
        }
        // Update is called once per frame
        void Update() {
            GroundCheck();
            GetPlayerInput();
        }
        
        private void FixedUpdate() {
            if (_dashing) {
                Dash();
            }
            if (_dashcooling) {
                DashCool();
            }

            if (_jumping) {
                Jump();
            }

            if (_jumpcooling) {
                JumpCool();
            }
            
            MovePlayer();
        }
        void GetPlayerInput() {
            _playerInputVector = new Vector3(Input.GetAxisRaw("Horizontal"), 0f, Input.GetAxisRaw("Vertical"));
            _playerInputVector = Quaternion.Euler(0, _playerInputAngleOffset, 0) * _playerInputVector;
            if (Input.GetKeyDown(KeyCode.D) && _ableToDash) {
                _dashing = true;
                _ableToDash = false;
            }
            if (Input.GetKeyDown(KeyCode.Space) && _ableToJump && _isGrounded) {
                _jumping = true;
                _ableToJump = false;
            }
        }
        void MovePlayer() {
            _playerMovementVector =
                _dashing ? _playerInputVector * (walkspeed * dashmultiplier) : _playerInputVector * walkspeed;
            _rigidbody.velocity = new Vector3(_playerMovementVector.x, _rigidbody.velocity.y, _playerMovementVector.z);

            if (OnSlope()) {
                _rigidbody.velocity = GetSlopeMoveDirection();
            }
        }
        void Dash() {
            _dashtimer += Time.deltaTime;
            if (_dashtimer >= _dashduration) {
                _dashtimer = 0;
                _dashing = false;
                _dashcooling = true;
            }
        }
        void DashCool() {
            _dashcooltimer += Time.deltaTime;
            if (_dashcooltimer >= _dashcoolduration) {
                _dashcooltimer = 0;
                _dashcooling = false;
                _ableToDash = true;
            }
        }

        void Jump() {
            _rigidbody.velocity = new Vector3(_rigidbody.velocity.x, 0, _rigidbody.velocity.z);
            _rigidbody.AddForce(Vector3.up * jumpvelocity, ForceMode.Impulse);
            _jumpcooling = true;
            _jumping = false;
        }

        void JumpCool() {
            _jumpcooltimer += Time.deltaTime;
            if (_jumpcooltimer >= _jumpcoolduration) {
                _jumpcooltimer = 0;
                _jumpcooling = false;
                _ableToJump = true;
            }
        }

        void GroundCheck() {
            _isGrounded = Physics.Raycast(transform.position, Vector3.down, _playerHeight * 0.5f + 0.3f, groundMask);
        }

        private bool OnSlope() {
            if (Physics.Raycast(transform.position, Vector3.down, out slopeHit, _playerHeight * 0.5f + 0.3f)) {
                float angle = Vector3.Angle(Vector3.up, slopeHit.normal);
                return angle < maxSlopeAngle && angle != 0;
            }
            return false;
        }

        private Vector3 GetSlopeMoveDirection() {
            return Vector3.ProjectOnPlane(_playerMovementVector, slopeHit.normal);
        }
    }
}
