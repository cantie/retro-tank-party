#!/usr/bin/env python3
"""
Convert Godot 3 TileMap data to Godot 4 format - Version 2 with transform support.

Godot 3 tile_data format (PoolIntArray, 3 ints per tile):
  - position: x | (y << 16) (both signed 16-bit)
  - tile_and_flags: tile_id | (flip_h << 29) | (flip_v << 30) | (transpose << 31)
  - alternative: usually 0

Godot 4 tile_data format (PackedInt32Array, 3 ints per tile):
  - position: same as Godot 3
  - source_and_atlas: source_id | (atlas_x << 16) | (atlas_y << 24)
  - alternative_tile: flip_h | (flip_v << 1) | (transpose << 2) for compatibility mode
    OR: TRANSFORM_FLIP_H (4096) | TRANSFORM_FLIP_V (8192) | TRANSFORM_TRANSPOSE (16384)
"""

import re
import sys
import subprocess

# Old tile ID -> (atlas_x, atlas_y) based on the original TileSet regions
# Derived from: tile_id/region = Rect2(x, y, 128, 128) -> atlas_x = x/128, atlas_y = y/128
TILE_ID_TO_ATLAS = {
    0:  (0, 0),   # Rect2(0, 0, 128, 128)
    1:  (0, 1),   # Rect2(0, 128, 128, 128)
    2:  (1, 0),   # Rect2(128, 0, 128, 128)
    3:  (2, 0),   # Rect2(256, 0, 128, 128)
    4:  (3, 0),   # Rect2(384, 0, 128, 128)
    5:  (4, 0),   # Rect2(512, 0, 128, 128)
    6:  (5, 0),   # Rect2(640, 0, 128, 128)
    7:  (6, 0),   # Rect2(768, 0, 128, 128)
    8:  (1, 1),   # Rect2(128, 128, 128, 128)
    9:  (2, 1),   # Rect2(256, 128, 128, 128)
    10: (3, 1),   # Rect2(384, 128, 128, 128)
    11: (4, 1),   # Rect2(512, 128, 128, 128)
    12: (5, 1),   # Rect2(640, 128, 128, 128)
    13: (6, 1),   # Rect2(768, 128, 128, 128)
    14: (0, 2),   # Rect2(0, 256, 128, 128)
    15: (0, 3),   # Rect2(0, 384, 128, 128)
    16: (1, 2),   # Rect2(128, 256, 128, 128)
    17: (2, 2),   # Rect2(256, 256, 128, 128)
    18: (3, 2),   # Rect2(384, 256, 128, 128)
    19: (4, 2),   # Rect2(512, 256, 128, 128)
    20: (5, 2),   # Rect2(640, 256, 128, 128)
    21: (6, 2),   # Rect2(768, 256, 128, 128)
    22: (1, 3),   # Rect2(128, 384, 128, 128)
    23: (2, 3),   # Rect2(256, 384, 128, 128)
    24: (3, 3),   # Rect2(384, 384, 128, 128)
    25: (4, 3),   # Rect2(512, 384, 128, 128)
    26: (5, 3),   # Rect2(640, 384, 128, 128)
    27: (6, 3),   # Rect2(768, 384, 128, 128)
    28: (7, 0),   # Rect2(896, 0, 128, 128)
    29: (8, 0),   # Rect2(1024, 0, 128, 128)
    30: (7, 1),   # Rect2(896, 128, 128, 128)
    31: (8, 1),   # Rect2(1024, 128, 128, 128)
    32: (7, 2),   # Rect2(896, 256, 128, 128)
    33: (8, 2),   # Rect2(1024, 256, 128, 128)
    34: (7, 3),   # Rect2(896, 384, 128, 128)
    35: (8, 3),   # Rect2(1024, 384, 128, 128)
    36: (9, 0),   # Rect2(1152, 0, 128, 128)
    37: (9, 1),   # Rect2(1152, 128, 128, 128)
    38: (9, 2),   # Rect2(1152, 256, 128, 128)
    39: (9, 3),   # Rect2(1152, 384, 128, 128)
}

# Godot 4 alternative tile IDs for transforms
# 0: no transform
# 1: flip_h
# 2: flip_v
# 3: flip_h + flip_v
# 4: transpose
# 5: transpose + flip_h
# 6: transpose + flip_v
# 7: transpose + flip_h + flip_v
def get_alternative_tile_id(flip_h, flip_v, transpose):
    """Convert transform flags to Godot 4 alternative tile ID."""
    return (flip_h * 1) + (flip_v * 2) + (transpose * 4)

def signed16(val):
    """Convert unsigned 16-bit to signed."""
    if val >= 0x8000:
        return val - 0x10000
    return val

def parse_godot3_tile_data(data_str):
    """Parse Godot 3 PoolIntArray tile_data string into list of tiles."""
    numbers = re.findall(r'-?\d+', data_str)
    values = [int(n) for n in numbers]
    
    tiles = []
    for i in range(0, len(values), 3):
        if i + 2 >= len(values):
            break
            
        pos = values[i]
        tile_flags = values[i + 1]
        alt = values[i + 2]
        
        # Decode position (signed 16-bit x and y)
        x = pos & 0xFFFF
        y = (pos >> 16) & 0xFFFF
        x = signed16(x)
        y = signed16(y)
        
        # Decode tile_flags (unsigned interpretation for flags)
        tile_flags_unsigned = tile_flags & 0xFFFFFFFF
        tile_id = tile_flags_unsigned & 0x1FFFFFFF  # Lower 29 bits
        flip_h = (tile_flags_unsigned >> 29) & 1
        flip_v = (tile_flags_unsigned >> 30) & 1
        transpose = (tile_flags_unsigned >> 31) & 1
        
        tiles.append({
            'x': x,
            'y': y,
            'tile_id': tile_id,
            'flip_h': flip_h,
            'flip_v': flip_v,
            'transpose': transpose,
        })
    
    return tiles

def tile_id_to_atlas_coords(tile_id):
    """Convert old tile ID to atlas coordinates using the lookup table."""
    if tile_id in TILE_ID_TO_ATLAS:
        return TILE_ID_TO_ATLAS[tile_id]
    else:
        print(f"Warning: Unknown tile ID {tile_id}, using fallback", file=sys.stderr)
        return (tile_id % 10, tile_id // 10)

def encode_godot4_tile_data(tiles, source_id=0):
    """Encode tiles into Godot 4 PackedInt32Array format with transform support."""
    values = []
    
    for tile in tiles:
        x, y = tile['x'], tile['y']
        tile_id = tile['tile_id']
        flip_h = tile['flip_h']
        flip_v = tile['flip_v']
        transpose = tile['transpose']
        
        # Position encoding (same as Godot 3)
        if x < 0:
            x = x & 0xFFFF
        if y < 0:
            y = y & 0xFFFF
        pos = x | (y << 16)
        
        # Convert to signed 32-bit
        if pos >= 0x80000000:
            pos = pos - 0x100000000
        
        # Atlas coordinates using the lookup table
        atlas_x, atlas_y = tile_id_to_atlas_coords(tile_id)
        
        # Source and atlas encoding for Godot 4
        # source_id | (atlas_x << 16) | (atlas_y << 24)
        source_atlas = source_id | (atlas_x << 16) | (atlas_y << 24)
        
        # Alternative tile ID for transforms (simple index, not bitmask)
        alternative = get_alternative_tile_id(flip_h, flip_v, transpose)
        
        values.extend([pos, source_atlas, alternative])
    
    return values

def format_packed_int32_array(values):
    """Format values as Godot 4 PackedInt32Array string."""
    return "PackedInt32Array(" + ", ".join(str(v) for v in values) + ")"

def get_original_content(input_path):
    """Get original file content from git (d36db94 has original Godot 3 format)."""
    rel_path = input_path.replace('/workspace/', '')
    result = subprocess.run(
        ['git', 'show', 'd36db94:' + rel_path],
        capture_output=True, text=True, cwd='/workspace'
    )
    if result.returncode == 0:
        return result.stdout
    return None

def convert_tscn_file(input_path, output_path=None):
    """Convert a .tscn file's TileMap data from Godot 3 to Godot 4 format."""
    if output_path is None:
        output_path = input_path
    
    # Get original Godot 3 content from git
    content = get_original_content(input_path)
    if content is None:
        print(f"Warning: Could not get original file from git for {input_path}", file=sys.stderr)
        return
    
    # Pattern to match the TileMap node with old format
    tilemap_pattern = r'(\[node name="TileMap" type="TileMap"[^\]]*\])\ntile_set = ([^\n]+)\ncell_size = [^\n]+\nformat = 1\ntile_data = PoolIntArray\(\s*([^)]+)\s*\)'
    
    def replace_tilemap(match):
        node_header = match.group(1)
        tileset_ref = match.group(2)
        tile_data_str = match.group(3)
        
        # Parse old tile data
        tiles = parse_godot3_tile_data(tile_data_str)
        print(f"Parsed {len(tiles)} tiles", file=sys.stderr)
        
        # Count transforms
        transforms = {}
        for t in tiles:
            key = (t['flip_h'], t['flip_v'], t['transpose'])
            transforms[key] = transforms.get(key, 0) + 1
        print(f"Transform counts: {transforms}", file=sys.stderr)
        
        # Convert to Godot 4 format with transforms
        new_values = encode_godot4_tile_data(tiles)
        new_tile_data = format_packed_int32_array(new_values)
        
        # Build new TileMap node
        new_node = f'''{node_header}
tile_set = {tileset_ref}
layer_0/tile_data = {new_tile_data}'''
        
        return new_node
    
    new_content = re.sub(tilemap_pattern, replace_tilemap, content, flags=re.DOTALL)
    
    with open(output_path, 'w') as f:
        f.write(new_content)
    
    print(f"Converted {input_path} -> {output_path}", file=sys.stderr)

if __name__ == '__main__':
    import glob
    
    # Convert all map files
    map_files = glob.glob('/workspace/mods/core/maps/*.tscn')
    for map_file in map_files:
        print(f"Converting {map_file}...", file=sys.stderr)
        convert_tscn_file(map_file)
    
    print("Done!", file=sys.stderr)
