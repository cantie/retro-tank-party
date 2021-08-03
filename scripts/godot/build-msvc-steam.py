#!/usr/bin/env python3

import os
import hashlib
import re

def calculate_directory_hash(top_dir):
    #presort_re = re.compile(r'_-\.')

    filepaths = []
    for (dirpath, dirnames, filenames) in os.walk(top_dir, False):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            filepaths.append(filepath.replace('\\', '/'))


    repl = ['_', '-', '.']
    def sortkey(x):
        #print (x)
        x = x.lower()
        for r in repl:
            x = x.replace(r, '')
        #print (x)
        return x
    
    #filepaths.sort(key=lambda x: x.lower().replace('_', '~'))
    filepaths.sort(key=sortkey)
    #filepaths.sort(key=lambda x: x.lower())

    hashes = []
    for filepath in filepaths:
        filehash = hashlib.md5(open(filepath, 'rb').read()).hexdigest()
        hashes.append(filehash + "  " + filepath.replace('\\', '/'))

    #print ('\n'.join(hashes))
    # The trailing dash is for compatibility with the shell version.
    return hashlib.md5('\n'.join(hashes).encode('utf-8')).hexdigest() + '-'

class BuildException(Exception):
    pass

def _strip_tarfile_members(archive, strip):
    for member in archive.getmembers():
        member.path = member.path.split('/', strip)[-1]
        yield member

def prepare_godot_build_dir(godot_source_dir, godot_build_dir):
    import tarfile
    import tempfile
    import urllib.request

    download_url_path = os.path.join(godot_source_dir, 'DOWNLOAD_URL')
    if not os.path.exists(download_url_path):
        raise BuildException("Source directory is missing required DOWNLOAD_URL file")

    if os.path.exists(godot_build_dir):
        print(" !! WARNING: Reusing existing build directory !! ")
        return
    os.mkdir(godot_build_dir)

    with open(download_url_path, 'rt') as fd:
        download_url = fd.read().strip()

    (archive_fd, archive_path) = tempfile.mkstemp('.tar.gz', 'godot-')
    archive_fd = os.fdopen(archive_fd, 'wb')

    try:
        with urllib.request.urlopen(download_url) as remote_fd:
            while True:
                buffer = remote_fd.read(8192)
                if not buffer:
                    break
                archive_fd.write(buffer)
    finally:
        archive_fd.close()

    try:
        with tarfile.open(archive_path, 'r:gz') as archive:
            archive.extractall(godot_build_dir, members=_strip_tarfile_members(archive, 1))
    finally:
        os.remove(archive_path)

def main():
    godot_source_dir = os.environ.get('GODOT_SOURCE_DIR', 'godot')
    godot_build_dir = os.environ.get('GODOT_BUILD_DIR', 'build/godot')
    force_rebuild_godot = os.environ.get('FORCE_REBUILD_GODOT', 'no')

    godot_archive_suffix = os.environ.get('GODOT_ARCHIVE_SUFFIX', '')

    if not os.path.exists(godot_source_dir):
        pass

    # @todo Not yet compatible with shell version.
    source_hash = calculate_directory_hash(godot_source_dir)
    #print(source_hash)

    prepare_godot_build_dir(godot_source_dir, godot_build_dir)

    oldcwd = os.getcwd()
    os.chdir(godot_build_dir)
    os.system('scons')
    os.chdir(oldcwd)

if __name__ == '__main__': main()

