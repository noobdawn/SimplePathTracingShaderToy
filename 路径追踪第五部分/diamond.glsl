// Generated from diamond.obj

bool TestHitDiamond(ray r, vec3 center, float scale, inout hitInfo hit) {
    bool isHit = false;

    const vec3 v[34] = vec3[](
        vec3(-0.146318, 1.143205, -0.735589),
        vec3(-0.416678, 1.143205, -0.623602),
        vec3(-0.623602, 1.143205, -0.416678),
        vec3(-0.735589, 1.143205, -0.146318),
        vec3(-0.735589, 1.143205, 0.146318),
        vec3(-0.623602, 1.143205, 0.416678),
        vec3(-0.416678, 1.143205, 0.623602),
        vec3(-0.146318, 1.143205, 0.735589),
        vec3(0.146318, 1.143205, 0.735589),
        vec3(0.416678, 1.143205, 0.623602),
        vec3(0.623602, 1.143205, 0.416678),
        vec3(0.735589, 1.143205, 0.146318),
        vec3(0.735589, 1.143205, -0.146318),
        vec3(0.623602, 1.143205, -0.416678),
        vec3(0.416678, 1.143205, -0.623602),
        vec3(0.146318, 1.143205, -0.735589),
        vec3(0.000000, 1.143205, -0.000000),
        vec3(0.000000, 0.000000, 0.000000),
        vec3(0.000000, 0.929266, -1.000000),
        vec3(-0.382683, 0.929266, -0.923880),
        vec3(-0.707107, 0.929266, -0.707107),
        vec3(-0.923880, 0.929266, -0.382683),
        vec3(-1.000000, 0.929266, -0.000000),
        vec3(-0.923880, 0.929266, 0.382683),
        vec3(-0.707107, 0.929266, 0.707107),
        vec3(-0.382683, 0.929266, 0.923880),
        vec3(0.000000, 0.929266, 1.000000),
        vec3(0.382683, 0.929266, 0.923880),
        vec3(0.707107, 0.929266, 0.707107),
        vec3(0.923880, 0.929266, 0.382683),
        vec3(1.000000, 0.929266, -0.000000),
        vec3(0.923880, 0.929266, -0.382683),
        vec3(0.707107, 0.929266, -0.707107),
        vec3(0.382683, 0.929266, -0.923880)
    );

    if (TestHitTriangle(r, v[10] * scale + center, v[11] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[3] * scale + center, v[4] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[11] * scale + center, v[12] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[4] * scale + center, v[5] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[12] * scale + center, v[13] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[5] * scale + center, v[6] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[13] * scale + center, v[14] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[6] * scale + center, v[7] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[14] * scale + center, v[15] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[7] * scale + center, v[8] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[0] * scale + center, v[1] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[15] * scale + center, v[0] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[8] * scale + center, v[9] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[1] * scale + center, v[2] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[9] * scale + center, v[10] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[2] * scale + center, v[3] * scale + center, v[16] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[18] * scale + center, v[33] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[33] * scale + center, v[32] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[32] * scale + center, v[31] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[31] * scale + center, v[30] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[30] * scale + center, v[29] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[29] * scale + center, v[28] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[28] * scale + center, v[27] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[27] * scale + center, v[26] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[26] * scale + center, v[25] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[25] * scale + center, v[24] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[24] * scale + center, v[23] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[23] * scale + center, v[22] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[22] * scale + center, v[21] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[21] * scale + center, v[20] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[20] * scale + center, v[19] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[19] * scale + center, v[18] * scale + center, v[17] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[20] * scale + center, v[21] * scale + center, v[2] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[2] * scale + center, v[21] * scale + center, v[3] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[21] * scale + center, v[22] * scale + center, v[3] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[4] * scale + center, v[22] * scale + center, v[23] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[3] * scale + center, v[22] * scale + center, v[4] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[4] * scale + center, v[23] * scale + center, v[5] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[23] * scale + center, v[24] * scale + center, v[5] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[5] * scale + center, v[24] * scale + center, v[6] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[24] * scale + center, v[25] * scale + center, v[6] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[6] * scale + center, v[25] * scale + center, v[7] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[25] * scale + center, v[26] * scale + center, v[7] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[7] * scale + center, v[26] * scale + center, v[8] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[26] * scale + center, v[27] * scale + center, v[8] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[8] * scale + center, v[27] * scale + center, v[9] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[27] * scale + center, v[28] * scale + center, v[9] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[9] * scale + center, v[28] * scale + center, v[10] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[28] * scale + center, v[29] * scale + center, v[10] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[10] * scale + center, v[29] * scale + center, v[11] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[29] * scale + center, v[30] * scale + center, v[11] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[11] * scale + center, v[30] * scale + center, v[12] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[30] * scale + center, v[31] * scale + center, v[12] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[12] * scale + center, v[31] * scale + center, v[13] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[31] * scale + center, v[32] * scale + center, v[13] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[13] * scale + center, v[32] * scale + center, v[14] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[32] * scale + center, v[33] * scale + center, v[14] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[14] * scale + center, v[33] * scale + center, v[15] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[33] * scale + center, v[18] * scale + center, v[15] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[15] * scale + center, v[18] * scale + center, v[0] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[18] * scale + center, v[19] * scale + center, v[0] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[0] * scale + center, v[19] * scale + center, v[1] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[19] * scale + center, v[20] * scale + center, v[1] * scale + center, hit)) isHit = true;
    if (TestHitTriangle(r, v[2] * scale + center, v[1] * scale + center, v[20] * scale + center, hit)) isHit = true;

    return isHit;
}
