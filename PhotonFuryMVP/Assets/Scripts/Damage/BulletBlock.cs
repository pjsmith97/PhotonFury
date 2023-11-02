using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BulletBlock : MonoBehaviour
{
    public Collider playerCollider;

    // Start is called before the first frame update
    void Start()
    {
        Physics.IgnoreCollision(this.GetComponent<Collider>(), playerCollider);
    }

    private void Awake()
    {
        //Physics.IgnoreCollision(this.GetComponent<Collider>(), playerCollider);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnCollisionEnter(Collision collision)
    {
        if(collision.gameObject.tag != "Enemy" &&
            collision.gameObject.tag != "Player"
            && collision.gameObject.tag != "Bullet")
        {
            Debug.Log("Hit something boring: " + collision.gameObject.name);
            Destroy(this.transform.parent.gameObject);
        }

        else if(collision.gameObject.tag == "Bullet" ||
            collision.gameObject.tag == "Enemy")
        {
            Physics.IgnoreCollision(this.GetComponent<Collider>(),
                collision.gameObject.GetComponent<Collider>());
        }
    }
}
