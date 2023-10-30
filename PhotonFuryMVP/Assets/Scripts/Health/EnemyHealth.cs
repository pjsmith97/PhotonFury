using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace photonfury.health
{
    public class EnemyHealth : Health
    {
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

            var parent = gameObject.transform.parent.gameObject;
            parent.SetActive(false);
        }
    }
}

