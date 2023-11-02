using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class bulletfire : MonoBehaviour
{
    public float FireSpeed = 2000f;

    public GameObject BulletToInstantiate;
    public Transform BarrelPosition;

    private void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Shoot();
        }
    }

    void Shoot()
    {
        GameObject BulletClone = Instantiate(BulletToInstantiate, BarrelPosition.position, BarrelPosition.rotation);
        Rigidbody rb = BulletClone.GetComponent<Rigidbody>();

        rb.AddForce(transform.forward * FireSpeed); //Adds a force in the direction the gun is facing (assuming that the script is attached to the gun
    }


}

