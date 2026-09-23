using UnityEngine;

// Add to the imported root. Speeds come from manifest.json (degrees/second).
public sealed class CosmosAnimation : MonoBehaviour
{
    public float rotationSpeed = 4f;
    public float cloudSpeed = 2f;
    private Transform clouds;
    private void Awake()
    {
        foreach (var child in GetComponentsInChildren<Transform>())
            if (child.name == "CloudShell") { clouds = child; break; }
    }
    private void Update()
    {
        transform.Rotate(Vector3.up, rotationSpeed * Time.deltaTime, Space.Self);
        if (clouds != null) clouds.Rotate(Vector3.up, cloudSpeed * Time.deltaTime, Space.Self);
    }
}
