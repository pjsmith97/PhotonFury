using System.Collections;
using System.Collections.Generic;
using photonfury.health;
using UnityEngine;

public class Bullet : MonoBehaviour
{
    [SerializeField] float bulletLife;

    [Header("Bullet Movement")]
    [SerializeField] Vector3 spawnPosition;
    [SerializeField] float timer = 0f;
    [SerializeField] float rotation;
    [SerializeField] float speed;

    [Header("Player Interaction")]
    [SerializeField] private GameObject _player;

    // Start is called before the first frame update
    void Start()
    {
        spawnPosition = this.transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        if(timer > bulletLife)
        {
            Destroy(this.gameObject);
        }
    }

    private void FixedUpdate()
    {
        timer += Time.deltaTime;

        transform.position = Movement();
    }

    private Vector3 Movement()
    {
        float newX = timer * speed * transform.right.x;
        float newZ = timer * speed * transform.right.z;

        return new Vector3(newX + spawnPosition.x, spawnPosition.y,
            newZ + spawnPosition.z);
    }

    public void SetUpBullet(float spd, Quaternion rot, float life,
        GameObject player)
    {
        speed = spd;
        this.transform.rotation = rot;
        bulletLife = life;
        _player = player;

        this.transform.GetChild(0).GetComponent<BulletBlock>().playerCollider =
            player.GetComponent<Collider>();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject == _player)
        {
            Debug.Log("Hit player");
            _player.GetComponent<PlayerHealth>().Damage(20); // Apply 20
                                                             // damage to player
            Destroy(this.gameObject);
        }

        else if (other.gameObject.tag != "Enemy" &&
            other.gameObject.tag != "Player"
            && other.gameObject.tag != "Bullet") 
        {
            Debug.Log("Hit object " + other.gameObject.name);
            Destroy(this.gameObject);
        }
    }
}
