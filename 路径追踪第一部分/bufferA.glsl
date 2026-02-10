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
};

// 参数定义
const float FOV = 60.0f;        // 视野角度
const float MAX_DIST = 100.0f;  // 最大追踪距离
const float MIN_DIST = 0.001f;    // 最小追踪距离
const float EPSILON = 0.001f;   // 误差范围

uint WangHash(inout uint Seed)
{
    Seed = (Seed ^ uint(61)) ^ (Seed >> uint(16));
    Seed *= uint(9);
    Seed = Seed ^ (Seed >> uint(4));
    Seed *= uint(0x27d4eb2d);
    Seed = Seed ^ (Seed >> uint(15));
    return Seed;
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
        if (t > MIN_DIST && t < MAX_DIST) {
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
    if (t > MIN_DIST && t < MAX_DIST) {
        hit.t = t;
        hit.pos = r.start + t * r.dir;
        hit.normal = normalize(cross(edge1, edge2));
        return true;
    }
    return false;
}

bool TestHitQuad(ray r, vec3 v0, vec3 v1, vec3 v2, vec3 v3, inout hitInfo hit) {
    // 使用两个三角形组成的四边形进行相交测试
    hitInfo tempHit;
    bool hit1 = TestHitTriangle(r, v0, v1, v2, tempHit);
    bool hit2 = TestHitTriangle(r, v2, v3, v0, tempHit);
    if (hit1 || hit2) {
        hit = tempHit;
        return true;
    }
    return false;
}

bool TestHitScene(ray r, out hitInfo hit) {
    bool hitSomething = false;
    hit.t = MAX_DIST;

    // 测试球体
    hitInfo tempHit;
    if (TestHitSphere(r, vec3(0.0f, 0.0f, 0.0f), 1.0f, tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    if (TestHitSphere(r, vec3(3.0f, 0.0f, 0.0f), 1.0f, tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    if (TestHitSphere(r, vec3(-3.0f, 0.0f, 0.0f), 1.0f, tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    // 测试盒子
    vec3 boxMin = vec3(-5.0, -1.0f, -3.0f);
    vec3 boxMax = vec3(5.0, 12.0f, 3.0f);
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMin.y, boxMin.z),
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        vec3(boxMin.x, boxMax.y, boxMin.z),
        tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    // 朝相机的一面不做测试
    // if (TestHitQuad(r, 
    //     vec3(boxMin.x, boxMin.y, boxMax.z),
    //     vec3(boxMax.x, boxMin.y, boxMax.z),
    //     vec3(boxMax.x, boxMax.y, boxMax.z),
    //     vec3(boxMin.x, boxMax.y, boxMax.z),
    //     tempHit)) {
    //     if (tempHit.t < hit.t) {
    //         hit = tempHit;
    //         hitSomething = true;
    //     }
    // }
    // 左侧面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMax.y, boxMin.z),
        vec3(boxMin.x, boxMax.y, boxMax.z),
        vec3(boxMin.x, boxMin.y, boxMax.z),
        vec3(boxMin.x, boxMin.y, boxMin.z),
        tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    // 右侧面
    if (TestHitQuad(r, 
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMax.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMax.y, boxMax.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    // 底面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMin.y, boxMax.z),
        vec3(boxMax.x, boxMin.y, boxMin.z),
        vec3(boxMin.x, boxMin.y, boxMin.z),
        tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    // 顶面
    if (TestHitQuad(r, 
        vec3(boxMin.x, boxMax.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMin.z),
        vec3(boxMax.x, boxMax.y, boxMax.z),
        vec3(boxMin.x, boxMax.y, boxMax.z),
        tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    // 测试光源
    vec3 lightMin = vec3(-2.0f, 12.0f - EPSILON, -2.0f);
    vec3 lightMax = vec3(2.0f, 12.0f - EPSILON, 2.0f);
    if (TestHitQuad(r,
        vec3(lightMin.x, lightMin.y, lightMin.z),
        vec3(lightMax.x, lightMin.y, lightMin.z),
        vec3(lightMax.x, lightMin.y, lightMax.z),
        vec3(lightMin.x, lightMin.y, lightMax.z),
        tempHit)) {
        if (tempHit.t < hit.t) {
            hit = tempHit;
            hitSomething = true;
        }
    }
    return hitSomething;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv.y = 1.0f - uv.y; // 翻转Y轴坐标，由于OpenGL的纹理坐标原点在左下角，我更习惯以左上角为原点
    float aspect = iResolution.x / iResolution.y;
    float fovScale = tan(radians(FOV * 0.5f));
    vec3 rayDir = normalize(vec3((uv.x - 0.5f) * 2.0f * aspect * fovScale, (0.5f - uv.y) * 2.0f * fovScale, -1.0f));
    ray r;
    r.start = vec3(0.0f, 5.0f, 30.0f); // 相机位置
    r.dir = rayDir;
    hitInfo hit;
    if (TestHitScene(r, hit)) {
        fragColor = vec4(hit.normal * 0.5f + 0.5f, 1.0f); // 根据法线着色
    }
    else {
        fragColor = vec4(0.0f, 0.0f, 0.0f, 1.0f); // 背景色
    }
}