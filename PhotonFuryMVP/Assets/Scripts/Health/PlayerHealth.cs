using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using photonfury.level;

namespace photonfury.health
{
    public class PlayerHealth : Health
    {

        [SerializeField] private RectTransform healthbar;

        private float healthbarwidth;
        private float healthbarwidth_default;

        [SerializeField] LevelProgressManager lvlPrgsManager;

        // Start is called before the first frame update
        protected override void Start()
        {
            //healthValue = maxHealth;
            base.Start();
            healthbarwidth_default = healthbar.rect.width;
        }

        public override void Damage(int dmgValue)
        {
            base.Damage(dmgValue);

            UpdateHealthBar();
        }

        void UpdateHealthBar()
        {
            var healthleft = (float)healthValue / (float)maxHealth;
            Debug.Log("Health: " + healthleft + " / " + maxHealth);

            float x = healthleft * healthbarwidth_default;
            healthbar.sizeDelta = new Vector2(x, 30);
        }

        //private void OnCollisionEnter(Collision other)
        //{
        //    Debug.Log("Player impulse = " + other.impulse.magnitude);
        //    if (other.gameObject.tag == "Enemy" && other.impulse.magnitude > 20f)
        //    {
        //        Debug.Log("Found Enemy");
        //        other.gameObject.GetComponent<EnemyHealth>().
        //            Damage(other.gameObject.GetComponent<EnemyHealth>().maxHealth);
        //    }
        //}

        public override void Death()
        {
            base.Death();
            this.transform.GetChild(2).gameObject.SetActive(false);

            lvlPrgsManager.gameOver = true;
        }
    }

}
