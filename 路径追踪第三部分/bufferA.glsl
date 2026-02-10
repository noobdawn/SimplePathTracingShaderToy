#include "common.glsl"
// 射线
struct ray {
    vec3 start; // 起点
    vec3 dir;   // 方向，已归一化
};

// 射线与物体相交信息
struct hitInfo {
    float t;      // 距离
    vec3 pos;     // 交点位置
    vec3 normal;  // 法线
    vec3 emission; // 自发光颜色
    vec3 albedo;   // 反射率
};

#iChannel0 "self"
#iChannel1 "file://路径追踪第三部分/env.png"

#define USE_AA  1
#ifndef USE_AA
    #define USE_AA 1
#endif

#define PI 3.14159265359f

// 参数定义
const float FOV = 60.0f;        // 视野角度
const float MAX_DIST = 100.0f;  // 最大追踪距离
const float MIN_DIST = 0.001f;    // 最小追踪距离
const float EPSILON = 0.001f;   // 误差范围
const int MAX_BOUNCES = 8;     // 最大反弹次数
const int SAMPLES_PER_PIXEL = 4; // 每像素采样次数

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

bool TestHitScene(ray r, inout hitInfo hit) {
    // 根据康奈尔盒子的经典设计
    const vec3 wallAlbedo = vec3(0.7f);
    const vec3 leftWallAlbedo = vec3(0.7f, 0.1f, 0.1f);
    const vec3 rightWallAlbedo = vec3(0.1f, 0.7f, 0.1f);
    const vec3 lightAlbedo = vec3(0.0f);
    const vec3 opaqueEmission = vec3(0.0f);
    const vec3 lightEmission = vec3(1.0f, 0.9f, 0.7f) * 20.0f;
    // 测试球体
    if (TestHitSphere(r, vec3(0.0f, 0.0f, 0.0f), 1.0f, hit)) {
        hit.albedo = wallAlbedo;
        hit.emission = opaqueEmission;
    }
    if (TestHitSphere(r, vec3(3.0f, 0.0f, 0.0f), 1.0f, hit)) {
        hit.albedo = wallAlbedo;
        hit.emission = opaqueEmission;
    }
    if (TestHitSphere(r, vec3(-3.0f, 0.0f, 0.0f), 1.0f, hit)) {
        hit.albedo = wallAlbedo;
        hit.emission = opaqueEmission;
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
            hit.albedo = wallAlbedo;
            hit.emission = opaqueEmission;
    }
    // 朝相机的一面不做测试
    // 左侧面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMax.y, boxMin.z),
        vec3(boxMin.x, boxMax.y, boxMax.z),
        vec3(boxMin.x, boxMin.y, boxMax.z),
        vec3(boxMin.x, boxMin.y, boxMin.z),
        hit)) {
            hit.albedo = leftWallAlbedo;
            hit.emission = opaqueEmission;
    }
    // 右侧面
    if (TestHitQuad(r, 
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMax.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMax.y, boxMax.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        hit)) {
            hit.albedo = rightWallAlbedo;
            hit.emission = opaqueEmission;
    }
    // 底面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMin.x, boxMin.y, boxMin.z),
        hit)) {
            hit.albedo = wallAlbedo;
            hit.emission = opaqueEmission;
    }
    // 顶面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMax.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMax.z),
        vec3(boxMin.x, boxMax.y, boxMax.z),
        hit)) {
            hit.albedo = wallAlbedo;
            hit.emission = opaqueEmission;
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
            hit.albedo = lightAlbedo;
            hit.emission = lightEmission;
    }
    return (hit.t < MAX_DIST);
}

vec2 rayDirToUV(vec3 dir) {
    float u = 0.5f + atan(dir.z, dir.x) / (2.0f * PI);
    float v = asin(dir.y) / PI - 0.5f;      // 因为前面我们已经翻转了Y轴，这里也必须做对应的翻转
    return vec2(u, v);
}

vec3 getColorFromRay(ray r, inout uint Seed) {
    vec3 finalColor = vec3(0.0f);
    vec3 throughput = vec3(1.0f);
    for (int bounce = 0; bounce < MAX_BOUNCES; ++bounce) {
        hitInfo hit;
        hit.t = MAX_DIST;
        if (TestHitScene(r, hit)) {
            finalColor += throughput * hit.emission;
            // 计算新的射线方向，漫反射
            vec3 target = hit.pos + hit.normal + ranUnitVector(Seed);
            r.start = hit.pos + hit.normal * EPSILON; // 避免自相交
            r.dir = normalize(target - hit.pos);
            throughput *= hit.albedo;
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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv.y = 1.0f - uv.y; // 翻转Y轴坐标，由于OpenGL的纹理坐标原点在左下角，我更习惯以左上角为原点
    float aspect = iResolution.x / iResolution.y;
    float fovScale = tan(radians(FOV * 0.5f));
    vec3 currentColor = vec3(0.0f);
    ray r;
    r.start = vec3(0.0f, 5.0f, 20.0f); // 相机位置
    uint Seed = uint(fragCoord.x) * 1973u + uint(fragCoord.y) * 9277u + uint(iFrame) * 26699u;
    for (int i = 0; i < SAMPLES_PER_PIXEL; ++i) {
        Seed += 15787u;
        vec2 jitter = vec2(0.0f);
        #if USE_AA
            jitter = vec2(rand01(Seed), rand01(Seed)) - 0.5f;
        #endif
        vec2 jitteredUV = uv + jitter / iResolution.xy;
        vec3 rayDir = normalize(vec3((jitteredUV.x - 0.5f) * 2.0f * aspect * fovScale, (0.5f - jitteredUV.y) * 2.0f * fovScale, -1.0f));
        r.dir = rayDir;
        vec3 color = getColorFromRay(r, Seed);
        currentColor += color;
    }
    currentColor /= float(SAMPLES_PER_PIXEL);
    // 与历史颜色进行混合
    vec2 sampleUV = uv;
    sampleUV.y = 1.0f - sampleUV.y;
    vec4 historyColor = texture(iChannel0, sampleUV);
    currentColor = mix(historyColor.rgb, currentColor, 1.0f / float(iFrame + 1));
    fragColor = vec4(currentColor, 1.0f);
}