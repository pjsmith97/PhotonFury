using System;
using System.Collections;
using System.Collections.Generic;
using photonfury.health;
using UnityEngine;

public class Laser : MonoBehaviour
{
    [SerializeField] private GameObject _player;
    private Collider _Collider;
    void Start()
    {
        _Collider = GetComponent<Collider>();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject == _player)
        {
            //Debug.Log("Health Pre-Damage: " +
            //    _player.GetComponent<PlayerHealth>().CurrentHealth());

            _player.GetComponent<PlayerHealth>().Damage(10); //When hit by
                                                             //laser, do 20 damage
            //Debug.Log("Health Post-Damage: " +
            //    _player.GetComponent<PlayerHealth>().CurrentHealth());
        }
    }
}
