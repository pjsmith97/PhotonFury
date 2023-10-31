using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using photonfury.pause;
using photonfury.health;

namespace photonfury.level
{
    public class LevelProgressManager : MonoBehaviour
    {
        [SerializeField] PlayerHealth playerHealth;
        public List<EnemyHealth> enemyHealths;

        [SerializeField] PauseGame pauseManager;

        [SerializeField] float yDeathValue;

        public bool gameOver;

        // Start is called before the first frame update
        void Start()
        {
            GameObject[] allEnemies = GameObject.FindGameObjectsWithTag("Enemy");

            enemyHealths = new List<EnemyHealth>();
            for (int e = 0; e < allEnemies.Length; e++)
            {
                EnemyHealth eHealth = allEnemies[e].GetComponent<EnemyHealth>();
                enemyHealths.Add(eHealth);
            }
        }

        // Update is called once per frame
        void Update()
        {
            if((gameOver || pauseManager.paused) && Input.GetKeyDown(KeyCode.R))
            {
                if (pauseManager.paused)
                {
                    Time.timeScale = 1;
                }

                SceneManager.LoadScene(SceneManager.GetActiveScene().name);
            }
        }

        private void FixedUpdate()
        {
            if(playerHealth.gameObject.transform.position.y < yDeathValue)
            {
                if (!pauseManager.paused)
                {
                    pauseManager.TogglePause();

                }
            }
        }

        public void CheckEnemyStatus()
        {
            int e = 0;
            bool enemiesExist = false;

            while (e < enemyHealths.Count && !enemiesExist)
            {
                enemiesExist = !(enemyHealths[e].AreUDed());
                e++;
            }

            if (!enemiesExist)
            {
                gameOver = true;
            }
        }
    }

}
