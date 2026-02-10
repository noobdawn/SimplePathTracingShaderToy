import os

def convert_obj_to_glsl(obj_file, glsl_file):
    if not os.path.exists(obj_file):
        print(f"Error: {obj_file} not found.")
        return

    vertices = []
    faces = []

    with open(obj_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            parts = line.split()
            if parts[0] == 'v':
                vertices.append([float(x) for x in parts[1:4]])
            elif parts[0] == 'f':
                # Handle f v1/vt1/vn1 v2/vt2/vn2 ...
                face = []
                for p in parts[1:]:
                    idx = int(p.split('/')[0])
                    # Obj indices are 1-based, convert to 0-based
                    if idx > 0:
                        face.append(idx - 1)
                    else:
                        face.append(len(vertices) + idx)
                faces.append(face)

    with open(glsl_file, 'w', encoding='utf-8') as f:
        f.write("// Generated from " + os.path.basename(obj_file) + "\n\n")
        f.write("bool TestHitDiamond(ray r, vec3 center, float scale, inout hitInfo hit) {\n")
        f.write("    bool isHit = false;\n\n")
        
        # Write vertices as an array
        f.write(f"    const vec3 v[{len(vertices)}] = vec3[](\n")
        for i, v in enumerate(vertices):
            comma = "," if i < len(vertices) - 1 else ""
            f.write(f"        vec3({v[0]:.6f}, {v[1]:.6f}, {v[2]:.6f}){comma}\n")
        f.write("    );\n\n")

        # Write face intersection tests
        for face in faces:
            if len(face) == 3:
                f.write(f"    if (TestHitTriangle(r, v[{face[0]}] * scale + center, v[{face[1]}] * scale + center, v[{face[2]}] * scale + center, hit)) isHit = true;\n")
            elif len(face) == 4:
                f.write(f"    if (TestHitQuad(r, v[{face[0]}] * scale + center, v[{face[1]}] * scale + center, v[{face[2]}] * scale + center, v[{face[3]}] * scale + center, hit)) isHit = true;\n")
            else:
                # Simple fan triangulation for n-gons
                for i in range(1, len(face) - 1):
                    f.write(f"    if (TestHitTriangle(r, v[{face[0]}] * scale + center, v[{face[i]}] * scale + center, v[{face[i+1]}] * scale + center, hit)) isHit = true;\n")

        f.write("\n    return isHit;\n")
        f.write("}\n")

    print(f"Generated {glsl_file} successfully with {len(vertices)} vertices and {len(faces)} faces.")

if __name__ == "__main__":
    # Hardcoded paths relative to workspace root as requested
    obj_path = r"路径追踪第五部分/diamond.obj"
    glsl_path = r"路径追踪第五部分/diamond.glsl"
    convert_obj_to_glsl(obj_path, glsl_path)
