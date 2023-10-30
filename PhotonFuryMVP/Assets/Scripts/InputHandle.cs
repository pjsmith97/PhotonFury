using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Example : MonoBehaviour
{
    public CharacterController characterController;
    private Vector3 velocity;
    public float Speed = 2f;
    public float jump = 10f;
    public float Gravity = -9.8f;
    void update()
    {
// for movement
        float horizontal = Input.GetAxis("Horizontal") * Speed;
        float vertical = Input.GetAxis("Vertical") *Speed;
        Vector3 move = transform.right * horizontal + transform.forward * vertical;
        characterController.Move(move * Speed * Time.deltaTime);
// for jump
        if (Input.GetKeyDown(KeyCode.Space) && transform.position.y< -0.51f)
// (-0.5) change this value according to your character y position + 1
        {
            velocity.y = jump;
        }
        else
        {
            velocity.y += Gravity * Time.deltaTime;
        }
        characterController.Move(velocity * Time.deltaTime);
    }
}