#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

static float frogSmooth(float value) {
    float t = clamp(value, 0.0f, 1.0f);
    return t*t*(3.0f-2.0f*t);
}

static float frogImpact(float time) {
    if (time < 1.26f) return 0;
    if (time < 1.32f) return frogSmooth((time-1.26f)/0.06f);
    if (time < 1.40f) return 1.0f-frogSmooth((time-1.32f)/0.08f);
    if (time < 1.46f) return 0.25f*frogSmooth((time-1.40f)/0.06f);
    return 0.25f*(1.0f-frogSmooth((time-1.46f)/0.10f));
}

// A small, inverse-mapped body rig. The feet remain planted; the face, eyes,
// mouth and beret move as one layer. SwiftUI supplies interpolated uniforms.
[[ stitchable ]] half4 croaFrogSoftMotion(float2 position, SwiftUI::Layer layer,
                                           float2 size, float padding,
                                           float breath, float yawn, float croak, float jumpProgress) {
    float2 uv = (position - padding) / max(size, float2(1.0));
    if (jumpProgress >= 0) {
        float time = clamp(jumpProgress, 0.0f, 1.0f) * 1.78f;
        float flight = clamp((time-0.36f)/0.94f, 0.0f, 1.0f);
        float lift = 76.0f * 4.0f * flight * (1.0f-flight) / 299.0f;
        float scaleY = 1.0f - 0.06f*sin(M_PI_F*clamp(time/0.36f, 0.0f, 1.0f)) - 0.10f*frogImpact(time);
        float scaleX = 1.0f + (1.0f-scaleY)*0.65f;
        uv.x = 0.5f + (uv.x-0.5f)/scaleX;
        uv.y = 1.0f + (uv.y+lift-1.0f)/scaleY;
    }
    float body = 1.0 - smoothstep(0.77, 0.94, uv.y);
    float head = 1.0 - smoothstep(0.50, 0.72, uv.y);
    float2 chestDelta = (uv - float2(0.50, 0.70)) / float2(0.32, 0.23);
    float chest = exp(-dot(chestDelta, chestDelta));
    float stretch = 0.018 * breath + 0.045 * yawn + 0.030 * croak;
    float2 source = uv;
    source.y = 0.90 + (source.y - 0.90) / (1.0 + stretch * body);
    source.x = 0.50 + (source.x - 0.50) / (1.0 + 0.018 * breath * chest + 0.018 * croak * head);
    float tilt = (-0.035 * yawn + 0.045 * croak) * head;
    float c = cos(tilt), s = sin(tilt);
    float2 delta = source - float2(0.50, 0.55);
    source = float2(0.50, 0.55) + float2(c*delta.x + s*delta.y, -s*delta.x + c*delta.y);
    return layer.sample(source * size + padding);
}
