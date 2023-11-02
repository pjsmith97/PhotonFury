using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using photonfury.level;

namespace photonfury.health
{
    public class EnemyHealth : Health
    {
        [SerializeField] LevelProgressManager lvlPrgsManager;
        [SerializeField] private ParticleSystem _particleSystem;

        // Start is called before the first frame update
        protected override void Start()
        {
            base.Start();
        }

        // Update is called once per frame
        private void Update()
        {
            
        }

        public override void Damage(int dmgValue)
        {
            base.Damage(dmgValue);
        }


        public override void Death()
        {
            base.Death();
            var transform1 = transform;
            Instantiate(_particleSystem, transform1.position, transform1.rotation);
            var parent = gameObject.transform.parent.gameObject;
            parent.SetActive(false);
            lvlPrgsManager.CheckEnemyStatus();
        }
    }
}

