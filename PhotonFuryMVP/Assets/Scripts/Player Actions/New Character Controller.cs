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
    [SerializeField] private float _walkspeed;
    [SerializeField] private float _jumpforce;
    [SerializeField] private float _dashforce;
    [SerializeField] private float _dashSpeed;
    private Rigidbody _rigidbody;

    private Vector3 PlayerMovementInput;

    [SerializeField] LevelProgressManager lvlPrgsManager;

    [Header ("Dashing")]
    public bool dashing;
    public float dashingTimer;
    [SerializeField] float dashingDuration;
    public int dashingDebugCntr;
    public int dashingEndDebugCntr;

    //[SerializeField] Animator _dashanimator;
    [SerializeField] MeshRenderer dashShield;
    [SerializeField] TrailRenderer trail;

//private bool isDed;

private void Start()
    {
        _rigidbody = GetComponent<Rigidbody>();
        dashingTimer = 0;
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

                //Debug.Log("Slowing...");
                    dashingEndDebugCntr += 1;
                    Debug.Log("Dashing End Counter: " + dashingEndDebugCntr);

                    //_dashanimator.SetBool("isOn", dashing);
                }
            }
    }

    void GetPlayerInput()
    {
        PlayerMovementInput = new Vector3(Input.GetAxisRaw("Horizontal"), 0f, Input.GetAxisRaw("Vertical"));
        PlayerMovementInput = Quaternion.Euler(0, 45, 0) * PlayerMovementInput;
    }

    void MovePlayer()
    {
        Vector3 MoveVector = dashing ?
            transform.TransformDirection(PlayerMovementInput) * _walkspeed * _dashSpeed :
            transform.TransformDirection(PlayerMovementInput) * _walkspeed;

        //MoveVector = Quaternion.Euler(0, 45, 0) * MoveVector;
        _rigidbody.velocity = new Vector3(MoveVector.x, _rigidbody.velocity.y, MoveVector.z);
        //Quaternion targetRotation = Quaternion.LookRotation(MoveVector);

        if (Input.GetKeyDown(KeyCode.Space))
        {
            _rigidbody.AddForce(Vector3.up * _jumpforce, ForceMode.Impulse);
        }

        if (Input.GetKeyDown(KeyCode.D) && dashingTimer == 0)
        {
            //_rigidbody.AddForce(PlayerMovementInput * _dashforce, ForceMode.Impulse);
            _rigidbody.velocity = PlayerMovementInput * _dashforce;
            dashing = true;

            dashingDebugCntr += 1;
            Debug.Log("Dashing Counter: " + dashingDebugCntr);
                
            //dashingTimer = 0;
            //Debug.Log("DASHING!");
            //_dashanimator.SetBool("isOn", dashing);
        }
    }

    //public void Death()
    //{
    //    isDed = true;
    //    this.transform.GetChild(2).gameObject.SetActive(false);
    //}
        
        
}
//}

