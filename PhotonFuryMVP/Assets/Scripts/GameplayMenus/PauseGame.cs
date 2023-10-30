using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace photonfury.pause
{
    public class PauseGame : MonoBehaviour
    {
        public bool paused;

        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {
            if (Input.GetKeyDown(KeyCode.P))
            {
                TogglePause();
            }
        }

        public void TogglePause()
        {
            if (!paused)
            {
                Time.timeScale = 0;
            }
            else
            {
                Time.timeScale = 1;
            }

            paused = !paused;
            
        }
    }
}

