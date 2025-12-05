// sphere with center in (0, 0, 0)
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// XZ plane
float sdPlane(vec3 p) {
    return p.y;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdCappedCylinder(vec3 p, float r, float h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float lazycos(float angle) {
    int nsleep = 10;
    int iperiod = int(angle / 6.28318530718) % nsleep;
    if (iperiod < 3) {
        return cos(angle);
    }
    return 1.0;
}

vec2 smin(float a, float b, float k) {
    float h = 1.0 - min(abs(a - b) / (6.0 * k), 1.0);
    float w = h * h * h;
    float m = w * 0.5;
    float s = w * k;
    return (a < b) ? vec2(a - s, m) : vec2(b - s, 1.0 - m);
}

vec4 sdBody(vec3 p) {
    float d1 = sdSphere((p - vec3(0.0, 0.35, -0.7)), 0.35);
    float d2 = sdSphere((p - vec3(0.0, 0.9, -0.7)), 0.25);
    vec2 smind = smin(d1, d2, 0.1);
    float dist = smind.x;
    vec3 color = vec3(1.0, 1.0, 0.0);
    return vec4(dist, color);
}

vec4 sdCap(vec3 p) {
    float d1 = sdCappedCylinder(p - vec3(0.0, 1.0, -0.7), 0.2, 0.2);
    float d2 = sdCappedCylinder(p - vec3(0.0, 1.3, -0.7), 0.1, 0.3);
    vec2 smind = smin(d1, d2, 0.04);
    vec3 color = vec3(0.0, 0.0, 0.0);
    return vec4(smind.x, color);
}

vec4 sdEye(vec3 p) {
    vec3 eye_pos = vec3(0.0, 0.86, -0.53);
    float eye = sdSphere(p - eye_pos, 0.15);
    vec3 iris_pos = eye_pos + vec3(0.0, 0.0, 0.1);
    float iris = sdSphere(p - iris_pos, 0.074);
    vec3 pupil_pos = iris_pos + vec3(0.0, 0.0, 0.03);
    float pupil = sdSphere(p - pupil_pos, 0.049);
    float d = eye;
    vec3 col = vec3(1.0, 1.0, 1.0);
    if (iris < d) { d = iris; col = vec3(1.0, 1.0, 0.0); }
    if (pupil < d) { d = pupil; col = vec3(0.0, 0.0, 0.0); }
    return vec4(d, col);
}

vec4 sdArm(vec3 p, vec3 a, vec3 b, vec3 c, float r) {
    float d1 = sdCapsule(p, a, b, r);
    float d2 = sdSphere(p - c, r);
    vec2 smind = smin(d1, d2, 0.02);
    return vec4(smind.x, vec3(0.0, 0.0, 0.0));
}

vec4 sdLeg(vec3 p, vec3 a, vec3 b, vec3 c, float r) {
    float d1 = sdCapsule(p, a, b, r);
    float d2 = sdCapsule(p, b, c, r);
    vec2 smind = smin(d1, d2, 0.02);
    return vec4(smind.x, vec3(0.0, 0.0, 0.0));
}

vec4 sdStaff(vec3 p, vec3 a, vec3 b, float r) {
    float d = sdCapsule(p, a, b, r);
    return vec4(d, vec3(0.0, 0.0, 0.0));
}

vec4 sdMonster(vec3 p) {
    float scale = 0.5;
    p /= scale;
    p += vec3(0.0, -0.6, 0.0);

    vec4 body = sdBody(p);
    vec4 eye = sdEye(p);
    vec4 cap = sdCap(p);

    vec2 u1 = smin(body.x, eye.x, 0.03);
    vec2 u2 = smin(u1.x, cap.x, 0.003);

    float shake = 0.045 * lazycos(iTime);

    vec3 armAL = vec3(-0.35, 0.6, -0.6);
    vec3 armBL = armAL + vec3(-0.3, 0.4, -0.1) + vec3(shake, 0.0, 0.0);
    vec3 armCL = armBL + vec3(-0.03, 0.04, 0.0) + vec3(shake, 0.0, 0.0);
    vec4 armL = sdArm(p, armAL, armBL, armCL, 0.07);

    vec3 armAR = vec3(0.35, 0.6, -0.6);
    vec3 armBR = armAR + vec3(0.3, 0.4, -0.1);
    vec3 armCR = armBR + vec3(0.03, 0.04, 0.0);
    vec4 armR = sdArm(p, armAR, armBR, armCR, 0.07);

    vec3 staffA = armBR;
    vec3 staffB = staffA + vec3(0.0, -2.0, 0.0);
    vec4 staff = sdStaff(p, staffA, staffB, 0.03);

    vec3 legAL = vec3(-0.15, 0.1, -0.7);
    vec3 legBL = legAL + vec3(0.0, -0.6, 0.0);
    vec3 legCL = legBL + vec3(0.0, -0.05, 0.05);
    vec4 legL = sdLeg(p, legAL, legBL, legCL, 0.07);

    vec3 legAR = vec3(0.15, 0.1, -0.7);
    vec3 legBR = legAR + vec3(0.0, -0.6, 0.0);
    vec3 legCR = legBR + vec3(0.0, -0.05, 0.05);
    vec4 legR = sdLeg(p, legAR, legBR, legCR, 0.07);

    vec2 u3 = smin(u2.x, armL.x, 0.03);
    vec2 u4 = smin(u3.x, armR.x, 0.03);
    vec2 u5 = smin(u4.x, staff.x, 0.03);
    vec2 u6 = smin(u5.x, legL.x, 0.03);
    vec2 u7 = smin(u6.x, legR.x, 0.03);

    float dist = u7.x;
    vec3 col = body.yzw;
    float mind = body.x;

    if (eye.x < mind) { mind = eye.x; col = eye.yzw; }
    if (cap.x < mind) { mind = cap.x; col = cap.yzw; }
    if (armL.x < mind) { mind = armL.x; col = armL.yzw; }
    if (armR.x < mind) { mind = armR.x; col = armR.yzw; }
    if (staff.x < mind) { mind = staff.x; col = staff.yzw; }
    if (legL.x < mind) { mind = legL.x; col = legL.yzw; }
    if (legR.x < mind) { mind = legR.x; col = legR.yzw; }

    return vec4(dist * scale, col);
}

vec4 sdTotal(vec3 p) {
    vec4 res = sdMonster(p);
    float dist = sdPlane(p);
    if (dist < res.x) {
        float scale = 2.0;
        float check = mod(floor(p.x * scale) + floor(p.z * scale), 2.0);
        vec3 colA = vec3(0.0);
        vec3 colB = vec3(1.0);
        vec3 chess = (check < 1.0) ? colA : colB;
        res = vec4(dist, chess);
    }
    return res;
}

vec3 calcNormal(in vec3 p) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps, 0);
    return normalize(vec3(
        sdTotal(p + h.xyy).x - sdTotal(p - h.xyy).x,
        sdTotal(p + h.yxy).x - sdTotal(p - h.yxy).x,
        sdTotal(p + h.yyx).x - sdTotal(p - h.yyx).x
    ));
}

vec4 raycast(vec3 ray_origin, vec3 ray_direction) {
    float EPS = 1e-3;
    float t = 0.0;
    for (int iter = 0; iter < 200; ++iter) {
        vec4 res = sdTotal(ray_origin + t * ray_direction);
        t += res.x;
        if (res.x < EPS) {
            return vec4(t, res.yzw);
        }
    }
    return vec4(1e10, vec3(0.0, 0.0, 0.0));
}

float shading(vec3 p, vec3 light_source, vec3 normal) {
    vec3 light_dir = normalize(light_source - p);
    float shading = dot(light_dir, normal);
    return clamp(shading, 0.5, 1.0);
}

float specular(vec3 p, vec3 light_source, vec3 N, vec3 camera_center, float shinyness) {
    vec3 L = normalize(p - light_source);
    vec3 R = reflect(L, N);
    vec3 V = normalize(camera_center - p);
    return pow(max(dot(R, V), 0.0), shinyness);
}

float castShadow(vec3 p, vec3 light_source) {
    vec3 light_dir = p - light_source;
    float target_dist = length(light_dir);
    if (raycast(light_source, normalize(light_dir)).x + 0.001 < target_dist) {
        return 0.5;
    }
    return 1.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.y;
    vec2 wh = vec2(iResolution.x / iResolution.y, 1.0);
    vec3 ray_origin = vec3(0.0, 0.5, 1.0);
    vec3 ray_direction = normalize(vec3(uv - 0.5 * wh, -1.0));

    vec4 res = raycast(ray_origin, ray_direction);

    float stripes = 30.0;
    float s = mod(floor(uv.x * stripes), 2.0);
    vec3 colA = vec3(1.0, 0.0, 0.0);
    vec3 colB = vec3(0.4, 0.0, 0.0);
    vec3 background = (s < 1.0) ? colA : colB;
    vec3 col = (res.x > 1e9) ? background : res.yzw;

    vec3 surface_point = ray_origin + res.x * ray_direction;
    vec3 normal = calcNormal(surface_point);

    vec3 light_source = vec3(1.0 + 2.5 * sin(iTime), 3.0, 15.0);
    float shad = shading(surface_point, light_source, normal);
    shad = min(shad, castShadow(surface_point, light_source));
    col *= shad;

    float spec = specular(surface_point, light_source, normal, ray_origin, 30.0);
    col += vec3(1.0, 1.0, 1.0) * spec;

    fragColor = vec4(col, 1.0);
}