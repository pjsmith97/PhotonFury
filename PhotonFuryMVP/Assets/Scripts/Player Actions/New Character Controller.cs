using System;
using System.Collections;
using System.Collections.Generic;
using photonfury.health;
using photonfury.level;
using UnityEngine;

public class NewCharacterController : MonoBehaviour
{
    [Header("Euler Isometric")]
    [SerializeField] float yValue;

    [Header ("Speeds")]
    [SerializeField] private float _walkspeed;
    [SerializeField] private float _jumpforce;
    [SerializeField] private float _dashforce;
    [SerializeField] private float _dashSpeed;
    private Rigidbody _rigidbody;

    private Vector3 PlayerMovementInput;

    [Header("Dashing")]
    public bool dashing;
    public bool dashingImpulse;
    public float dashingTimer;
    public float dashingCoolDownTimer;
    [SerializeField] float dashingCoolDownDuration;
    [SerializeField] float dashingDuration;
    public int dashingDebugCntr;
    public int dashingEndDebugCntr;
    [SerializeField] MeshRenderer dashShield;
    [SerializeField] TrailRenderer trail;
    private PlayerHealth playerHealth;

    [Header ("Level Manager")]
    [SerializeField] LevelProgressManager lvlPrgsManager;

    

    //[SerializeField] Animator _dashanimator;

//private bool isDed;

private void Start()
    {
        _rigidbody = GetComponent<Rigidbody>();
        dashingTimer = 0;
        dashingCoolDownTimer = dashingCoolDownDuration;
        playerHealth = GetComponent<PlayerHealth>();
        //isDed = false;
    }

    private void Update()
    {
        GetPlayerInput();
            

        if (dashing)
        {
            dashShield.enabled = true;
            trail.time = 0.5f;
        }

        else if (dashShield.enabled)
        {
            dashShield.enabled = false;
            trail.time = 0;
        }
    }

    private void FixedUpdate()
    {
        if (!lvlPrgsManager.gameOver)
        {
            MovePlayer();
        }

        if (dashing)
        {
            dashingTimer += Time.deltaTime;

            if(dashingTimer >= dashingDuration)
            {
                dashingTimer = 0;
                dashing = false;

                dashingEndDebugCntr += 1;
                Debug.Log("Dashing End Counter: " + dashingEndDebugCntr);

                dashingCoolDownTimer = dashingCoolDownDuration;

                playerHealth.invincible = false;
            }
        }

        else if(dashingCoolDownTimer > 0)
        {
            dashingCoolDownTimer -= Time.deltaTime;

            if (dashingCoolDownTimer <= 0)
            {
                dashingCoolDownTimer = 0;
            }
        }
    }

    void GetPlayerInput()
    {
        PlayerMovementInput = new Vector3(Input.GetAxisRaw("Horizontal"), 0f, Input.GetAxisRaw("Vertical"));
        PlayerMovementInput = Quaternion.Euler(0, yValue, 0) * PlayerMovementInput;

        if (Input.GetKeyDown(KeyCode.D) && dashingTimer == 0 && dashingCoolDownTimer == 0)
        {
            dashing = true;
            dashingImpulse = true;

            dashingDebugCntr += 1;
            Debug.Log("Dashing Counter: " + dashingDebugCntr);

            playerHealth.invincible = true;
        }
    }

    void MovePlayer()
    {
        Vector3 MoveVector = dashing ?
            transform.TransformDirection(PlayerMovementInput) * (_walkspeed * _dashSpeed) :
            transform.TransformDirection(PlayerMovementInput) * _walkspeed;

        //MoveVector = Quaternion.Euler(0, 45, 0) * MoveVector;
        _rigidbody.velocity = new Vector3(MoveVector.x, _rigidbody.velocity.y, MoveVector.z);
        //Quaternion targetRotation = Quaternion.LookRotation(MoveVector);

        if (Input.GetKeyDown(KeyCode.Space))
        {
            _rigidbody.AddForce(Vector3.up * _jumpforce, ForceMode.Impulse);
        }

        if (dashingImpulse)
        {
            dashingImpulse = false;

            _rigidbody.velocity = PlayerMovementInput * _dashforce;
                
            //dashingTimer = 0;
            //Debug.Log("DASHING!");
            //_dashanimator.SetBool("isOn", dashing);
        }
    }
        
        
}

