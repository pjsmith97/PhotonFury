using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using photonfury.health;

public class DashAttack : MonoBehaviour
{

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void FixedUpdate()
    {
        //trail.endColor = new Color(1,
        //    this.transform.GetComponentInParent<Rigidbody>().velocity.magnitude / 5f, 1);
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.tag == "Enemy" &&
            this.transform.GetComponentInParent<NewCharacterController>().dashing)
        {
            Debug.Log("Found Enemy Enter");
            //if(this.transform.GetComponentInParent<Rigidbody>().velocity.magnitude >= 10f)
            //{
                Debug.Log("Hit Enemy Enter");
                Physics.IgnoreCollision(
                this.transform.GetComponentInParent<Collider>(), other); // Ignore rigidbodycollisions with enemy

                other.gameObject.GetComponent<EnemyHealth>().
                    Damage(other.gameObject.GetComponent<EnemyHealth>().maxHealth);
            //}

            //else
            //{
            //    Debug.Log("Not fast enough: " +
            //        this.transform.GetComponentInParent<Rigidbody>().velocity.magnitude
            //        + " Speed");
            //}
            
        }
    }

    private void OnTriggerStay(Collider other)
    {
        if(other.gameObject.tag == "Enemy" &&
            this.transform.GetComponentInParent <NewCharacterController>().dashing)
        {
            Debug.Log("Found Enemy Stay");
            //if(this.transform.GetComponentInParent<Rigidbody>().velocity.magnitude >= 10f)
            //{
                Debug.Log("Hit Enemy Stay");
                Physics.IgnoreCollision(
                this.transform.GetComponentInParent<Collider>(), other); // Ignore collisions with enemy

                other.gameObject.GetComponent<EnemyHealth>().
                    Damage(other.gameObject.GetComponent<EnemyHealth>().maxHealth);
            //}

            //else
            //{
            //    Debug.Log("Not fast enough: " +
            //        this.transform.GetComponentInParent<Rigidbody>().velocity.magnitude
            //        + " Speed");
            //}
        }

        else if(other.gameObject.tag == "Enemy" &&
            Physics.GetIgnoreCollision
            (this.transform.GetComponentInParent<Collider>(), other))
        {
            Physics.IgnoreCollision(
                this.transform.GetComponentInParent<Collider>(), other, false);
        }
        
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.gameObject.tag == "Enemy" &&
            Physics.GetIgnoreCollision
            (this.transform.GetComponentInParent<Collider>(), other))
        {
            Physics.IgnoreCollision(
                this.transform.GetComponentInParent<Collider>(), other, false);
        }
    }
}
