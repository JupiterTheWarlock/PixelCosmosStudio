import io
import pathlib
import time
import zipfile
import requests

URL = 'https://godot-releases.nbg1.your-objectstorage.com/4.4.1-stable/Godot_v4.4.1-stable_export_templates.tpz'
DEST = pathlib.Path(__file__).resolve().parent.parent / '.tools' / 'templates' / '4.4.1.stable'

class RangeFile(io.RawIOBase):
    def __init__(self):
        self.session = requests.Session()
        self.size = 1206040900
        self.position = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position if whence == 1 else self.size) + offset
        return self.position
    def read(self, n=-1):
        n = self.size-self.position if n < 0 else min(n,self.size-self.position)
        if n <= 0: return b''
        start = self.position
        for attempt in range(4):
            try:
                response = self.session.get(URL, headers={'Range':f'bytes={start}-{start+n-1}', 'Accept-Encoding':'identity'}, timeout=120)
                response.raise_for_status()
                if response.status_code != 206 or len(response.content) != n:
                    raise RuntimeError(f'Range response: {response.status_code}, {len(response.content)} / {n}')
                self.position += n
                return response.content
            except (requests.RequestException, RuntimeError):
                if attempt == 3: raise
                time.sleep(2)

DEST.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(RangeFile()) as archive:
    wanted = {'web_nothreads_release.zip', 'web_nothreads_debug.zip', 'windows_release_x86_64.exe', 'windows_debug_x86_64.exe', 'version.txt'}
    for info in archive.infolist():
        name = pathlib.PurePosixPath(info.filename).name
        if name not in wanted: continue
        target = DEST / name
        if target.exists() and target.stat().st_size == info.file_size:
            print('Present:', name, flush=True)
        else:
            print('Downloading:', name, info.compress_size, flush=True)
            target.write_bytes(archive.read(info))
            print('Verified:', name, info.file_size, flush=True)
        wanted.remove(name)
    if wanted: raise RuntimeError(f'Missing templates: {wanted}')
