using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace photonfury.health
{
    public abstract class Health : MonoBehaviour
    {
        protected int healthValue;
        public int maxHealth;

        private bool isDed;

        // Start is called before the first frame update
        protected virtual void Start()
        {
            healthValue = maxHealth;
        }

        // Update is called once per frame
        void Update()
        {

        }

        public virtual void Damage(int dmgValue)
        {
            healthValue -= dmgValue;

            if (healthValue <= 0)
            {
                Death();
                Debug.Log(this.gameObject.name + " is Dead");
            }
            else
            {
                Debug.Log("Hit, Losing Health");
            }
            //UpdateHealthBar();
        }

        public virtual void Death()
        {
            isDed = true;
            //this.transform.GetChild(2).gameObject.SetActive(false);
        }

        public bool AreUDed()
        {
            return isDed;
        }

        public int CurrentHealth()
        {
            return healthValue;
        }
    }

}
