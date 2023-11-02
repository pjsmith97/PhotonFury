using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BulletSpawner : MonoBehaviour
{
    enum SpawnerType {Straight, Spin }

    [Header("General Bullet Attributes")]
    [SerializeField] GameObject bulletPrefab;
    [SerializeField] float bulletLife;
    [SerializeField] float speed;
    [SerializeField] GameObject player;

    [Header("Spawner Attributes")]
    [SerializeField] SpawnerType spawnerType;
    [SerializeField] float BPM;
    [SerializeField] float bulletsPerBeat;
    [SerializeField] float spinSpeed;
    [SerializeField] bool doubleFire;
    private float firingRate;
    public float timer = 0f;

    [Header("New Bullets")]
    private GameObject spawnedBullet;
    

    // Start is called before the first frame update
    void Start()
    {
        UpdateFiringRate();
    }

    // Update is called once per frame
    void Update()
    {
        UpdateFiringRate();

        if (timer >= firingRate)
        {
            Fire();
            timer = 0f;
        }
    }

    private void FixedUpdate()
    {
        timer += Time.deltaTime;

        if(spawnerType == SpawnerType.Spin)
        {
            transform.localEulerAngles = new Vector3(0f,
                transform.localEulerAngles.y + spinSpeed, 0f);
        }
        
    }

    private void Fire()
    {
        if (bulletPrefab) // Check if bullet prefab exists
        {
            spawnedBullet = Instantiate(bulletPrefab, transform.position,
                Quaternion.identity); // Instantiate new bullet 

            spawnedBullet.GetComponent<Bullet>().SetUpBullet(speed,
                transform.rotation, bulletLife, player); // Set up Bullet attributes

            Physics.IgnoreCollision(this.GetComponent<Collider>(),
                spawnedBullet.transform.GetComponent<Collider>());

            if (doubleFire)
            {
                spawnedBullet = Instantiate(bulletPrefab, transform.position,
                Quaternion.identity); // Instantiate new bullet 

                spawnedBullet.GetComponent<Bullet>().SetUpBullet(-speed,
                    transform.rotation, bulletLife, player); // Set up Bullet attributes

                Physics.IgnoreCollision(this.GetComponent<Collider>(),
                    spawnedBullet.transform.GetComponent<Collider>());
            }
        }
    }

    public void UpdateBPM(int newBPM)
    {
        BPM = newBPM; // Assign new BPM
    }

    public void UpdateBulletsPerBeat(int newBull)
    {
        bulletsPerBeat = newBull; //Assign new bullets per beat
    }

    public void UpdateFiringRate()
    {
        firingRate = 60 / BPM;
        firingRate /= bulletsPerBeat; // Calculate how many bullets are
                                      // spawning per beat

        //Debug.Log("Firing Rate: " + firingRate);
    }
}
