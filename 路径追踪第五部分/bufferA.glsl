#include "common.glsl"
// 射线
struct ray {
    vec3 start;         // 起点
    vec3 dir;           // 方向，已归一化
    int bounceCount;    // 反弹次数
};

struct material {
    vec3 emission;          // 自发光颜色
    vec3 albedo;            // 反射率
    vec3 specularColor;     // 镜面反射颜色
    vec3 absorption;        // 吸收系数，影响透射光的衰减
    float roughness;        // 粗糙度
    float ior;              // 折射率
    float transmission;     // 透射率，0~1之间
    float dispersion;       // 色散率
};

// 射线与物体相交信息
struct hitInfo {
    float t;                // 距离
    vec3 pos;               // 交点位置
    vec3 normal;            // 法线
    material mat;           // 物体材质信息
};

#iChannel0 "self"
#iChannel1 "file://路径追踪第五部分/env.png"

#define USE_AA  1
#ifndef USE_AA
    #define USE_AA 1
#endif

#define PI 3.14159265359f

// 参数定义
const float FOV = 40.0f;        // 视野角度
const float MAX_DIST = 100.0f;  // 最大追踪距离
const float MIN_DIST = 0.001f;    // 最小追踪距离
const float EPSILON = 0.001f;   // 误差范围
const int MAX_BOUNCES = 8;     // 最大反弹次数
const int MIN_BOUNCES = 2;     // 最小反弹次数
const int SAMPLES_PER_PIXEL = 12; // 每像素采样次数

// 折射率定义
const float IOR_AIR = 1.0f;     // 空气
const float IOR_GLASS = 1.5f;   // 玻璃
const float IOR_WATER = 1.33f;  // 水
const float IOR_DIAMOND = 2.42f; // 钻石

// 材质定义
const material MAT_LIGHT = material(
    vec3(15.0f, 12.0f, 8.0f), // 自发光
    vec3(0.0f),               // 反射率
    vec3(0.0f),               // 镜面反射颜色
    vec3(0.0f),               // 吸收系数
    1.0f,                     // 粗糙度
    IOR_AIR,                  // 折射率
    0.0f,                     // 透射率
    0.0f                      // 色散率
);
const material MAT_LEFT_WALL = material(
    vec3(0.0f),               // 自发光
    vec3(0.7f, 0.1f, 0.1f),   // 反射率
    vec3(0.0f),               // 镜面反射颜色
    vec3(0.0f),               // 吸收系数
    1.0f,                     // 粗糙度
    IOR_AIR,                  // 折射率
    0.0f,                     // 透射率
    0.0f                      // 色散率
);
const material MAT_RIGHT_WALL = material(
    vec3(0.0f),               // 自发光
    vec3(0.1f, 0.7f, 0.1f),   // 反射率
    vec3(0.0f),               // 镜面反射颜色
    vec3(0.0f),               // 吸收系数
    1.0f,                     // 粗糙度
    IOR_AIR,                  // 折射率
    0.0f,                     // 透射率
    0.0f                      // 色散率
);
const material MAT_WALL = material(
    vec3(0.0f),               // 自发光
    vec3(0.7f),               // 反射率
    vec3(0.0f),               // 镜面反射颜色
    vec3(0.0f),               // 吸收系数
    1.0f,                     // 粗糙度
    IOR_AIR,                  // 折射率
    0.0f,                     // 透射率
    0.0f                      // 色散率
);
const material MAT_MIRROR = material(
    vec3(0.0f),               // 自发光
    vec3(0.0f),               // 反射率
    vec3(1.0f),               // 镜面反射颜色
    vec3(0.0f),               // 吸收系数
    0.0f,                     // 粗糙度
    IOR_AIR,                  // 折射率
    0.0f,                     // 透射率
    0.0f                      // 色散率
);
const material MAT_DIAMOND = material(
    vec3(0.0f),               // 自发光
    vec3(1.0f),               // 反射率
    vec3(1.0f),               // 镜面反射颜色
    vec3(0.0f),               // 吸收系数
    0.0f,                     // 粗糙度
    IOR_DIAMOND,              // 折射率
    1.0f,                     // 透射率
    0.044f                    // 色散率
);
const material MAT_GLASS = material(
    vec3(0.0f),               // 自发光
    vec3(0.0f),               // 反射率
    vec3(1.0f),               // 镜面反射颜色
    vec3(1.5f, 1.2f, 0.2f),   // 吸收系数，使 R 和 G 吸收更快，从而呈现蓝色调
    0.0f,                     // 粗糙度
    IOR_GLASS,                // 折射率
    1.0f,                     // 透射率
    0.0f                      // 色散率
);


uint WangHash(inout uint Seed)
{
    Seed = (Seed ^ uint(61)) ^ (Seed >> uint(16));
    Seed *= uint(9);
    Seed = Seed ^ (Seed >> uint(4));
    Seed *= uint(0x27d4eb2d);
    Seed = Seed ^ (Seed >> uint(15));
    return Seed;
}

float rand01(inout uint Seed)
{
    return float(WangHash(Seed)) / 4294967296.0;
}

vec3 ranUnitVector(inout uint Seed)
{
    float z = rand01(Seed) * 2.0f - 1.0f;
    float a = rand01(Seed) * 6.28318530718f; // 2*PI
    float r = sqrt(1.0f - z * z);
    float x = r * cos(a);
    float y = r * sin(a);
    return vec3(x, y, z);
}

bool TestHitSphere(ray r, vec3 center, float radius, inout hitInfo hit) {
    vec3 oc = r.start - center;
    float a = dot(r.dir, r.dir);
    float b = 2.0f * dot(oc, r.dir);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - 4.0f * a * c;
    if (discriminant < 0.0f) {
        return false;
    } else {
        float t = (-b - sqrt(discriminant)) / (2.0f * a);
        if (t > MIN_DIST && t < MAX_DIST && t < hit.t) {
            hit.t = t;
            hit.pos = r.start + t * r.dir;
            hit.normal = normalize(hit.pos - center);
            return true;
        }
        t = (-b + sqrt(discriminant)) / (2.0f * a);
        if (t > MIN_DIST && t < MAX_DIST && t < hit.t) {
            hit.t = t;
            hit.pos = r.start + t * r.dir;
            hit.normal = normalize(hit.pos - center);
            return true;
        }
    }
    return false;
}

bool TestHitTriangle(ray r, vec3 v0, vec3 v1, vec3 v2, inout hitInfo hit) {
    vec3 edge1 = v1 - v0;
    vec3 edge2 = v2 - v0;
    vec3 h = cross(r.dir, edge2);
    float a = dot(edge1, h);
    if (abs(a) < EPSILON) {
        return false; // 射线与三角形平行
    }
    float f = 1.0f / a;
    vec3 s = r.start - v0;
    float u = f * dot(s, h);
    if (u < 0.0f || u > 1.0f) {
        return false;
    }
    vec3 q = cross(s, edge1);
    float v = f * dot(r.dir, q);
    if (v < 0.0f || u + v > 1.0f) {
        return false;
    }
    float t = f * dot(edge2, q);
    if (t > MIN_DIST && t < MAX_DIST && t < hit.t) {
        hit.t = t;
        hit.pos = r.start + t * r.dir;
        hit.normal = normalize(cross(edge1, edge2));
        return true;
    }
    return false;
}

bool TestHitQuad(ray r, vec3 v0, vec3 v1, vec3 v2, vec3 v3, inout hitInfo hit) {
    // 使用两个三角形组成的四边形进行相交测试
    bool hit1 = TestHitTriangle(r, v0, v1, v2, hit);
    bool hit2 = TestHitTriangle(r, v2, v3, v0, hit);
    if (hit1 || hit2) {
        return true;
    }
    return false;
}

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

bool TestHitScene(ray r, inout hitInfo hit) {
    // 根据康奈尔盒子的经典设计
    // 测试模型
    if (TestHitDiamond(r, vec3(0.0f, 0.0f, 0.0f), 2.5f, hit)) {
        hit.mat = MAT_GLASS;
    }
    // 测试盒子
    vec3 boxMin = vec3(-5.0, -1.0f, -3.0f);
    vec3 boxMax = vec3(5.0, 12.0f, 3.0f);
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMin.y, boxMin.z),
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        vec3(boxMin.x, boxMax.y, boxMin.z),
        hit)) {
            hit.mat = MAT_WALL;
    }
    // 朝相机的一面不做测试
    // 底面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMin.x, boxMin.y, boxMin.z),
        hit)) {
            hit.mat = MAT_WALL;
    }
    // 顶面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMax.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMax.z),
        vec3(boxMin.x, boxMax.y, boxMax.z),
        hit)) {
            hit.mat = MAT_WALL;
    }
    // 左边
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMin.y, boxMin.z),
        vec3(boxMin.x, boxMax.y, boxMin.z),
        vec3(boxMin.x, boxMax.y, boxMax.z),
        vec3(boxMin.x, boxMin.y, boxMax.z),
        hit)) {
            hit.mat = MAT_LEFT_WALL;
    }
    // 右边
    if (TestHitQuad(r, 
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMax.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMax.y, boxMax.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        hit)) {
            hit.mat = MAT_RIGHT_WALL;
    }
    // 测试光源
    vec3 lightMin = vec3(-2.0f, 12.0f - EPSILON, -2.0f);
    vec3 lightMax = vec3(2.0f, 12.0f - EPSILON, 2.0f);
    if (TestHitQuad(r,
        vec3(lightMin.x, lightMin.y, lightMin.z),
        vec3(lightMax.x, lightMin.y, lightMin.z),
        vec3(lightMax.x, lightMin.y, lightMax.z),
        vec3(lightMin.x, lightMin.y, lightMax.z),
        hit)) {
            hit.mat = MAT_LIGHT;
    }
    return (hit.t < MAX_DIST);
}

vec2 rayDirToUV(vec3 dir) {
    float u = 0.5f + atan(dir.z, dir.x) / (2.0f * PI);
    float v = asin(dir.y) / PI - 0.5f;// 天空球纹理需要坐标翻转
    return vec2(u, v);
}

/// 计算菲涅尔反射系数
/// n1: 入射介质的折射率
/// n2: 出射介质的折射率
/// normal: 法线，已归一化，指向入射介质
/// incident: 入射方向，已归一化，指向入射介质
float FresnelReflectAmount(float n1, float n2, vec3 normal, vec3 incident)
{
    // Schlick aproximation
    float r0 = (n1-n2) / (n1+n2);
    r0 *= r0;
    float cosX = -dot(normal, incident);
    if (n1 > n2)
    {
        float n = n1/n2;
        float sinT2 = n*n*(1.0-cosX*cosX);
        // Total internal reflection
        if (sinT2 > 1.0)
            return 1.0;
        cosX = sqrt(1.0-sinT2);
    }
    float x = 1.0-cosX;
    float ret = r0+(1.0-r0)*x*x*x*x*x;
    return ret;
}

vec3 getColorFromRay(ray r, inout uint Seed, int channel) {
    vec3 finalColor = vec3(0.0f);
    vec3 throughput = vec3(1.0f);

    // RGB过滤
    // 若命中带有色散效果的材质，则每次随机考虑这个ray代表的是红色、绿色还是蓝色的光线
    // 这时候需要调整传输率强度，以满足能量守恒
    vec3 channelMask = vec3(1.0f);
    bool hitDispersion = false;

    for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce) {
        hitInfo hit;
        hit.t = MAX_DIST;
        if (TestHitScene(r, hit)) {
            finalColor += throughput * hit.mat.emission;
            // 在考虑折射和反射前，先对折射率进行色散处理
            float ior = hit.mat.ior;
            if (hit.mat.dispersion > 0.0f) {
                hitDispersion = true;
                if (channel == 0) ior *= (1.0f - 0.5f * hit.mat.dispersion); // 红色光线折射率较低
                else if (channel == 2) ior *= (1.0f + 0.5f * hit.mat.dispersion); // 蓝色光线折射率较高
                // 调整传输率以满足能量守恒
                if (channelMask == vec3(1.0f))
                {
                    if (channel == 0) channelMask = vec3(3.0f, 0.0f, 0.0f);
                    else if (channel == 1) channelMask = vec3(0.0f, 3.0f, 0.0f);
                    else if (channel == 2) channelMask = vec3(0.0f, 0.0f, 3.0f);
                    throughput *= channelMask;
                }
            }

            // 如果是从内部出射到空气中，需要交换折射率，并且翻转法线
            float n1 = IOR_AIR;
            float n2 = ior;
            vec3 normal = hit.normal;
            bool fromInside = false;
            if (dot(r.dir, hit.normal) > 0.0f) {
                // 从内部射向外部
                n1 = ior;
                n2 = IOR_AIR;
                normal = -hit.normal;
                fromInside = true;
            }
            float reflectProb = FresnelReflectAmount(n1, n2, normal, r.dir);
            
            // 如果是在内部传播，应用 Beer-Lambert 定律进行体积吸收
            if (fromInside) {
                throughput *= exp(-hit.mat.absorption * hit.t);
            }

            bool isReflect = true;
            if (hit.mat.transmission > 0.0f) {
                if (rand01(Seed) >= reflectProb) {
                    isReflect = false; // 只有当材质有透射性且随机数大于反射率时，才走折射
                }
            }
            if (isReflect)
            {
                // 计算新的射线方向，漫反射
                vec3 diffuseDir = normal + ranUnitVector(Seed);
                vec3 reflectDir = reflect(r.dir, normal);
                r.start = hit.pos + normal * EPSILON; // 避免自相交，使用朝向入射侧的法线
                r.dir = mix(reflectDir, normalize(diffuseDir), pow(hit.mat.roughness, 1.3f)); // 略作调整，使得粗糙度为0.5的时候符合直觉
                throughput *= mix(hit.mat.specularColor, hit.mat.albedo, hit.mat.roughness);
                r.bounceCount += 1;
            }
            else
            {
                // 计算新的射线方向，折射
                vec3 microNormal = normalize(normal + ranUnitVector(Seed)); // 微表面法线，使用朝向入射侧的法线
                vec3 microRefractDir = refract(r.dir, microNormal, n1 / n2);
                vec3 refractDir = refract(r.dir, normal, n1 / n2);
                r.start = hit.pos - normal * EPSILON;
                r.dir = mix(refractDir, microRefractDir, pow(hit.mat.roughness, 1.3f)); // 略作调整，使得粗糙度为0.5的时候符合直觉
                r.bounceCount += 1;
                // 折射后的传输系数
                throughput *= hit.mat.transmission;
            }
            // 保证至少反弹一定次数，避免过早终止
            if (r.bounceCount >= MIN_BOUNCES) {
                // 俄罗斯轮盘赌
                float p = max(throughput.r, max(throughput.g, throughput.b));
                if (p == 0.0f || rand01(Seed) > p) {
                    break;
                }
                throughput /= p; // 因为概率为p的光线被提前终止，对于期望来说，另一部分未被终止的光线传输率就要调整，以保证期望不变
            }
        } else {
            // 未击中任何物体，采样天空盒
            vec3 skyColor = texture(iChannel1, rayDirToUV(r.dir)).rgb;
            vec3 skyLinearColor = SRGBToLinear(skyColor);
            finalColor += throughput * skyLinearColor;
            break;
        }
    }
    return finalColor;
}

// mouse camera control parameters
const float c_pi = 3.14159265359f;
const float c_minCameraAngle = 0.01f;
const float c_maxCameraAngle = (c_pi - 0.01f);
const vec3 c_cameraAt = vec3(0.0f, 5.0f, 0.0f);
const float c_cameraDistance = 20.0f;
 
void GetCameraVectors(out vec3 cameraPos, out vec3 cameraFwd, out vec3 cameraUp, out vec3 cameraRight)
{
    // if the mouse is at (0,0) it hasn't been moved yet, so use a default camera setup
    vec2 mouse = iMouse.xy;
    if (dot(mouse, vec2(1.0f, 1.0f)) == 0.0f)
    {
        cameraPos = vec3(0.0f, 5.0f, -c_cameraDistance);
        cameraFwd = vec3(0.0f, 0.0f, 1.0f);
        cameraUp = vec3(0.0f, 1.0f, 0.0f);
        cameraRight = vec3(1.0f, 0.0f, 0.0f);
        return;
    }
     
    // otherwise use the mouse position to calculate camera position and orientation
     
    float angleX = -mouse.x * 16.0f / float(iResolution.x);
    float angleY = mix(c_minCameraAngle, c_maxCameraAngle, mouse.y / float(iResolution.y));
     
    cameraPos.x = sin(angleX) * sin(angleY) * c_cameraDistance;
    cameraPos.y = -cos(angleY) * c_cameraDistance;
    cameraPos.z = cos(angleX) * sin(angleY) * c_cameraDistance;
     
    cameraPos += c_cameraAt;
     
    cameraFwd = normalize(c_cameraAt - cameraPos);
    cameraRight = normalize(cross(vec3(0.0f, 1.0f, 0.0f), cameraFwd));
    cameraUp = normalize(cross(cameraFwd, cameraRight));   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv.y = 1.0f - uv.y; // 翻转Y轴坐标，由于OpenGL的纹理坐标原点在左下角，我更习惯以左上角为原点
    float aspect = iResolution.x / iResolution.y;
    float fovScale = tan(radians(FOV * 0.5f));
    vec3 currentColor = vec3(0.0f);
    ray r;
    r.bounceCount = 0;
    vec3 cameraPos, cameraFwd, cameraUp, cameraRight;
    GetCameraVectors(cameraPos, cameraFwd, cameraUp, cameraRight);
    r.start = cameraPos; // 相机位置
    uint Seed = uint(fragCoord.x) * 1973u + uint(fragCoord.y) * 9277u + uint(iFrame) * 26699u;
    for (int i = 0; i < SAMPLES_PER_PIXEL; ++i) {
        Seed += 15787u;
        vec2 jitter = vec2(0.0f);
        #if USE_AA
            jitter = vec2(rand01(Seed), rand01(Seed)) - 0.5f;
        #endif
        vec2 jitteredUV = uv + jitter / iResolution.xy;
        mat3 camToWorld = mat3(cameraRight, cameraUp, cameraFwd);

        // 计算当前采样的射线方向
        vec3 viewDir = vec3((jitteredUV.x * 2.0f - 1.0f) * aspect * fovScale, (1.0f - jitteredUV.y * 2.0f) * fovScale, 1.0f);
        r.dir = normalize(camToWorld * viewDir);
        r.bounceCount = 0;

        int channel = int(rand01(Seed) * 3.0f); // 随机选择一个颜色通道进行采样
        vec3 color = getColorFromRay(r, Seed, channel);
        currentColor += color;
    }
    currentColor /= float(SAMPLES_PER_PIXEL);
    // 与历史颜色进行混合
    vec2 sampleUV = uv;
    sampleUV.y = 1.0f - sampleUV.y;
    vec4 historyColor = texture(iChannel0, sampleUV);

    // 使用alpha通道作为帧数
    float frame = historyColor.a;
    if (iMouse.z > 0.0f || iFrame == 0) {
        // 如果鼠标按下，重置历史颜色，重新开始累积
        frame = 1.0f;
    }
    else {
        // 否则继续累积历史颜色
        frame += 1.0f;
    }
    float weight = 1.0f / frame;
    vec3 blendedColor = mix(historyColor.rgb, currentColor, weight);
    fragColor = vec4(blendedColor, frame);
}