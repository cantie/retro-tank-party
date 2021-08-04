#!/usr/bin/env python3

import os
import hashlib
import re

class BuildException(Exception):
    pass

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

def _download_as_temp_file(url):
    import tempfile
    from urllib.request import urlopen
    from urllib.parse import urlparse

    parsed = urlparse(url)
    filename = parsed.path.split('/')[-1]
    (filename, extension) = filename.split('.', 1)

    (temp_fd, temp_path) = tempfile.mkstemp('.' + extension if extension else '', filename + '-')
    temp_fd = os.fdopen(temp_fd, 'wb')

    try:
        with urlopen(url) as remote_fd:
            while True:
                buffer = remote_fd.read(8192)
                if not buffer:
                    break
                temp_fd.write(buffer)
    except Exception as e:
        temp_fd.close()
        os.remove(temp_path)
        raise e

    temp_fd.close()

    return temp_path

def _strip_archive_members(archive, strip):
    if strip == 0:
        return archive.getmembers()
    for member in archive.getmembers():
        member.path = member.path.split('/', strip)[-1]
        yield member

def download_and_extract(url, destination, strip=0):
    import zipfile
    import tarfile

    archive_path = _download_as_temp_file(url)

    try:
        if archive_path.endswith('.tar.gz'):
            with tarfile.open(archive_path, 'r:gz') as archive:
                archive.extractall(destination, members=_strip_archive_members(archive, strip))
        elif archive_path.endswith('.zip'):
            with zipfile.ZipFile(archive_path, 'r') as archive:
                if strip != 0:
                    print(" ** WARNING: strip not supported for zip files")
                archive.extractall(destination)
        else:
            raise BuildError(F"Cannot extract archive {archive_path} with unknown type")
    finally:
        os.remove(archive_path)

def download_steam_sdk(dest_dir, src_files):
    import shutil
    from tempfile import TemporaryDirectory

    src_files = list(filter(lambda x: not os.path.exists(os.path.join(dest_dir, os.path.basename(x))), src_files))
    if len(src_files) == 0:
        print (" ** WARNING: all Steam SDK files already exist - skipping download")
        return

    if not 'STEAM_SDK_URL' in os.environ:
        raise BuildException("The STEAM_SDK_URL must be set to use this script.")
    steam_sdk_url = os.environ['STEAM_SDK_URL']

    with TemporaryDirectory(None, 'steam-sdk-') as temp_dir:
        download_and_extract(steam_sdk_url, temp_dir)

        for src_file in src_files:
            full_src_path = os.path.join(temp_dir, 'sdk', src_file)
            full_dest_path = os.path.join(dest_dir, os.path.basename(src_file))
            if os.path.exists(full_dest_path):
                print (F" ** WARNING: {full_dest_path} already exists - skipping")
                continue
            if os.path.isdir(full_src_path):
                shutil.copytree(full_src_path, full_dest_path)
            else:
                shutil.copyfile(full_src_path, full_dest_path)

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

    download_and_extract(download_url, godot_build_dir, strip=1)

def main():
    godot_source_dir = os.environ.get('GODOT_SOURCE_DIR', 'godot')
    godot_build_dir = os.environ.get('GODOT_BUILD_DIR', os.path.join('build', 'godot'))
    force_rebuild_godot = os.environ.get('FORCE_REBUILD_GODOT', 'no')

    godot_archive_suffix = os.environ.get('GODOT_ARCHIVE_SUFFIX', '')

    if not os.path.exists(godot_source_dir):
        pass

    # @todo Not yet compatible with shell version.
    source_hash = calculate_directory_hash(godot_source_dir)
    #print(source_hash)

    # @todo Can we seperate this from the more generic stuff in this script?
    download_steam_sdk(os.path.join(godot_source_dir, 'modules', 'godotsteam', 'sdk'), ['public', 'redistributable_bin'])

    prepare_godot_build_dir(godot_source_dir, godot_build_dir)

    # @todo How to pull in the steam redistributables? Port that script to Python too?

    num_cores = os.cpu_count()
    scons_extra = ''

    module_source_path = os.path.join(godot_source_dir, 'modules')
    if os.path.exists(module_source_path):
        module_source_path_relative = os.path.relpath(os.path.abspath(module_source_path), os.path.abspath(godot_build_dir))
        if os.path.sep != '/':
            # scons wants this with UNIX-style path seperators.
            module_source_path_relative = module_source_path_relative.replace(os.path.sep, '/')
        scons_extra += F' "custom_modules={module_source_path_relative}"'

    oldcwd = os.getcwd()
    os.chdir(godot_build_dir)
    scons_cmd = F"scons -j{num_cores} platform=windows target=release tools=no production=yes progress=no" + scons_extra
    print (F"Running {scons_cmd}...")
    exit_code = os.system(scons_cmd)
    os.chdir(oldcwd)

    if exit_code != 0:
        raise BuildException("scons build failed!")

if __name__ == '__main__': main()

