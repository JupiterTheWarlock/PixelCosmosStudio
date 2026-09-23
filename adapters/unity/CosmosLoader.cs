using System;
using System.IO;
using System.Threading.Tasks;
using UnityEngine;
using GLTFast;

// Requires com.unity.cloud.gltfast 6.7.1. Does not modify the game's render pipeline.
public sealed class CosmosLoader : MonoBehaviour
{
    [Serializable] public class Parameters { public float rotation_speed; public float cloud_speed; public bool pixel_art; }
    [Serializable] public class Manifest { public int version; public string domain; public Parameters parameters; }
    private GltfImport importer;
    public async Task<bool> LoadFolder(string folder)
    {
        if (importer != null) throw new InvalidOperationException("Use one CosmosLoader per asset.");
        var manifest = JsonUtility.FromJson<Manifest>(File.ReadAllText(Path.Combine(folder,"manifest.json")));
        if (manifest.version != 2 || manifest.domain != "planet") throw new InvalidDataException("Expected a v2 planet.");
        importer = Application.isPlaying ? new GltfImport() : new GltfImport(deferAgent: new UninterruptedDeferAgent());
        var loaded = await importer.Load(new Uri(Path.GetFullPath(Path.Combine(folder,"planet.glb"))).AbsoluteUri);
        if (!loaded || !await importer.InstantiateMainSceneAsync(transform)) return false;
        foreach (var renderer in GetComponentsInChildren<Renderer>())
            foreach (var material in renderer.sharedMaterials)
                if (material.mainTexture != null) material.mainTexture.filterMode = manifest.parameters.pixel_art ? FilterMode.Point : FilterMode.Bilinear;
        var motion = gameObject.AddComponent<CosmosAnimation>();
        motion.rotationSpeed = manifest.parameters.rotation_speed;
        motion.cloudSpeed = manifest.parameters.cloud_speed;
        return true;
    }
    private void OnDestroy() { importer?.Dispose(); }
}
