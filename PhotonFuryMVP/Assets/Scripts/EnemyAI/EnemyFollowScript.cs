using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class EnemyFollowScript : MonoBehaviour
{
    private NavMeshAgent navAgent;

    [SerializeField] Transform playerTransform;

    // Start is called before the first frame update
    void Start()
    {
        navAgent = this.GetComponent<NavMeshAgent>();
    }



    // Update is called once per frame
    void Update()
    {
        //Debug.Log(playerTransform.position);
        navAgent.SetDestination(playerTransform.position);
    }

    //public virtual void OnDrawGizmos()
    //{
    //    Gizmos.color = Color.green;
    //    Gizmos.DrawLine(transform.position, navAgent.destination);
    //}
}
