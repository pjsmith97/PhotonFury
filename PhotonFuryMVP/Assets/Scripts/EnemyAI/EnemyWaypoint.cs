using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyWaypoint : MonoBehaviour
{
    [SerializeField]
    protected float debugDrawRadius;

    [SerializeField]
    protected float proximityRadius; // Max proximity of neighbor waypoints

    public List<EnemyWaypoint> neighbours;

    public void Start()
    {
        // Find all waypoints in the scene
        GameObject[] allWaypoints = GameObject.FindGameObjectsWithTag("EnemyWaypoint");

        neighbours = new List<EnemyWaypoint>();

        // Check if waypoints are close enough
        for (int w = 0; w < allWaypoints.Length; w++)
        {
            EnemyWaypoint nextWaypoint = allWaypoints[w].GetComponent<EnemyWaypoint>();

            if (nextWaypoint != null)
            {
                if (Vector3.Distance(this.transform.position,
                    nextWaypoint.transform.position)
                    <= proximityRadius && nextWaypoint != this)
                {
                    neighbours.Add(nextWaypoint);
                }
            }
        }
    }

    public virtual void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, debugDrawRadius);

        Gizmos.color = Color.magenta;
        Gizmos.DrawWireSphere(transform.position, proximityRadius);
    }

    public EnemyWaypoint NextWaypoint(EnemyWaypoint previousWaypoint)
    {
        if (neighbours.Count == 0)
        {
            Debug.LogError("Need more waypoints");
            return null;
        }

        else if (neighbours.Count == 1 && neighbours.Contains(previousWaypoint))
        {
            return previousWaypoint;
        }

        else
        {
            EnemyWaypoint nextWaypoint;

            int nextIndex = 0;

            do
            {
                nextIndex = UnityEngine.Random.Range(0, neighbours.Count);
                nextWaypoint = neighbours[nextIndex];

            } while (nextWaypoint == previousWaypoint);

            return nextWaypoint;
        }
    }
}
