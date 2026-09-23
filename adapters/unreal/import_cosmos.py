"""UE Editor Python: import one exported planet folder, using stock glTF import.
Requires Python Editor Script Plugin and the engine's glTF/Interchange importer.
No runtime dependency. Coordinates/units are converted by Unreal's importer.
"""
import json
from pathlib import Path
import unreal

def import_planet(export_folder, destination='/Game/PixelCosmos'):
    folder=Path(export_folder)
    manifest=json.loads((folder/'manifest.json').read_text(encoding='utf-8'))
    if manifest.get('version')!=2 or manifest.get('domain')!='planet':
        raise ValueError('Expected Pixel Cosmos v2 planet export')
    task=unreal.AssetImportTask()
    task.filename=str(folder/'planet.glb')
    task.destination_path=destination
    task.automated=False  # Show importer options; no guessed engine-version defaults.
    task.replace_existing=False
    task.save=True
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    paths=list(task.imported_object_paths)
    if not paths:
        raise RuntimeError('No assets imported; check the glTF/Interchange import log')
    for asset_path in paths:
        asset=unreal.load_asset(asset_path)
        if isinstance(asset,unreal.Texture2D):
            asset.set_editor_property('filter',unreal.TextureFilter.TF_NEAREST)
            unreal.EditorAssetLibrary.save_loaded_asset(asset)
    unreal.log('Pixel Cosmos imported: '+str(paths))
    return paths
