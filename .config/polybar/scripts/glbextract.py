#!/usr/bin/env python3
"""	The MIT License(MIT)
	Copyright(c), Tobey Peters, https://github.com/tobeypeters
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without restriction,
	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
	LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

""" glbextract.py
	Description:
		Generates 2 c style arrays points and edges, from a .glb 3d model file.
        May contain some HolyC syntax also.
"""
import numpy as np
import trimesh #https://trimesh.org/install.html
import os

from pathlib import Path
from argparse import ArgumentParser, Namespace as arg_namespace

def is_file(parser, arg) -> str:
    if not Path(arg).is_file():
        parser.error(f"File '{arg}' not found.")

    return arg

# Argument parsing
parser: ArgumentParser = ArgumentParser(description="Converts GLB formated 3D mesh into C-style vertex and edge arrays.")
parser.add_argument('input_file',
    type=lambda f : is_file(parser, f),
    help='Path to the .glb file')
parser.add_argument("-o", "--output", help="Output file name (default: <glb_name>.c)")
parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output")
parser.add_argument("--no-edges", action="store_true", help="Exclude edges from output")
args = parser.parse_args()

# Get the GLB file path from command-line arguments
glb_file_path: str = args.input_file
# Extract the base filename (without extension)
base_name:    str = os.path.splitext(os.path.basename(glb_file_path))[0].upper()
shape_points: str = f"SHP_{base_name}_POINTS"
shape_edges:  str = f"SHP_{base_name}_EDGES"
base_name=base_name.lower()
base_points: str = f"{base_name}_points"
base_edges: str =  f"{base_name}_edges"

output_file:  str = args.output if args.output else f"./models/{base_name}.c"

# Load the GLB file
mesh = trimesh.load(glb_file_path, force="mesh")

# Extract vertices and edges
vertices = np.array(mesh.vertices)
edges = np.array(mesh.edges_unique)

# Remove duplicate vertices and remap edges
unique_vertices, inverse_indices = np.unique(vertices, axis=0, return_inverse=True)
remapped_edges = inverse_indices[edges]

# Write to C file
with open(output_file, "w") as f:
    f.write(f"#define {shape_points} {len(unique_vertices)}\n")
    f.write(f"//#define OBJ_POINTS {shape_points}\n\n")

    if not args.no_edges:
        f.write(f"#define {shape_edges} {len(remapped_edges)}\n")
        f.write(f"//#define OBJ_EDGES {shape_edges}\n\n")

    # Vertex array
    f.write(f"Point3D {base_points}[{shape_points}] = {{\n")
    for v in unique_vertices:
        f.write(f"    {{ {v[0]:.4f}, {v[1]:.4f}, {v[2]:.4f} }},\n")
    f.write("};\n\n")

    # Edge array (optional)
    if not args.no_edges:
        f.write(f"Edge {base_edges}[{shape_edges}] = {{\n")
        for e in remapped_edges:
            f.write(f"    {{ {e[0]}, {e[1]} }},\n")
        f.write("};\n\n")

    f.write(f"//CD3 *p_obj=&{base_points};\n")
    if not args.no_edges:
        f.write(f"//CD2 *v_obj=&{base_edges};\n\n")

# Verbose output
if args.verbose:
    print(f"         Loaded: {glb_file_path}");
print(f"Output saved to: {output_file}")
if args.verbose:
    print(f"Unique vertices: {len(unique_vertices)}")
    if not args.no_edges:
        print(f"          Edges: {len(remapped_edges)}")
