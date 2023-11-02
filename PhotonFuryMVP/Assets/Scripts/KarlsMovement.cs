using System;
using System.Numerics;
using photonfury.health;
using UnityEngine;
using UnityEngine.EventSystems;
using Quaternion = UnityEngine.Quaternion;
using Vector3 = UnityEngine.Vector3;
using Rewired;

namespace Karl.Movement.YesPhillipNoticeMyNameSpace {
    public class KarlsMovement : MonoBehaviour {
        private Rigidbody _rigidbody;
        
        [Header("Movement Parameters")]
        [SerializeField] private float walkspeed = 5;
        [SerializeField] private float dashmultiplier = 2;
        
        [Header("PlayerInput")]
        private Vector3 _playerInputVector;
        private float _playerInputAngleOffset = 225;
        private int playerID = 0;
        private Player rewiredPlayer;
        
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
        public bool dashing = false;
        private bool _ableToDash = true;
        private float _dashtimer;
        private bool _dashcooling = false;
        private float _dashcooltimer;
        
        [SerializeField] GameObject dashShield;
        [SerializeField] TrailRenderer trail;
        public GameObject dashUI;
        
        private PlayerHealth _playerHealth;

        [Header("Slope Handling")]
        [SerializeField] private float maxSlopeAngle = 45;
        private RaycastHit slopeHit;
        
        // Start is called before the first frame update
        void Start() {
            _rigidbody = GetComponent<Rigidbody>();
            _playerHealth = GetComponent<PlayerHealth>();

            rewiredPlayer = ReInput.players.GetPlayer(playerID);
        }
        // Update is called once per frame
        void Update() {
            GroundCheck();
            GetPlayerInput();

            _playerHealth.invincible = dashing;
            dashShield.SetActive(dashing);
            trail.gameObject.SetActive(dashing);
            trail.time = dashing ?  0.5f : 0;
        }
        
        private void FixedUpdate() {
            if (dashing) {
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
            _playerInputVector = new Vector3(rewiredPlayer.GetAxisRaw("Horizontal"), 0f, rewiredPlayer.GetAxisRaw("Vertical"));
            _playerInputVector = Quaternion.Euler(0, _playerInputAngleOffset, 0) * _playerInputVector;
            if (rewiredPlayer.GetButtonDown("Dash") && _ableToDash) {
                dashing = true;
                _ableToDash = false;
                dashUI.transform.GetChild(1).gameObject.SetActive(false);
            }
            if (rewiredPlayer.GetButtonDown("Jump") && _ableToJump && _isGrounded) {
                _jumping = true;
                _ableToJump = false;
            }
        }
        void MovePlayer() {
            _playerMovementVector =
                dashing ? _playerInputVector * (walkspeed * dashmultiplier) : _playerInputVector * walkspeed;
            _rigidbody.velocity = new Vector3(_playerMovementVector.x, _rigidbody.velocity.y, _playerMovementVector.z);

            if (OnSlope()) {
                _rigidbody.velocity = GetSlopeMoveDirection();
            }
        }
        void Dash() {
            _dashtimer += Time.deltaTime;
            dashUI.transform.localScale = Vector3.one * ((_dashduration - _dashtimer) / _dashduration);
            if (_dashtimer >= _dashduration) {
                _dashtimer = 0;
                dashing = false;
                _dashcooling = true;
            }
        }
        void DashCool() {
            _dashcooltimer += Time.deltaTime;
            dashUI.transform.localScale = Vector3.one * (_dashcooltimer / _dashcoolduration);
            if (_dashcooltimer >= _dashcoolduration) {
                _dashcooltimer = 0;
                _dashcooling = false;
                _ableToDash = true;
                dashUI.transform.localScale = Vector3.one;
                dashUI.transform.GetChild(1).gameObject.SetActive(true);

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
