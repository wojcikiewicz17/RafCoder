#include <jni.h>
#include <cinttypes>
#include <cstdio>

extern "C" {
#include "sector.h"
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_rafcoder_app_MainActivity_nativeMessage(JNIEnv* env, jobject /* this */) {
    return env->NewStringUTF("RafCoder Native Bridge OK — RAFAELOS core linked");
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_rafcoder_app_MainActivity_nativeSectorReport(JNIEnv* env, jobject /* this */, jint iterations) {
    state s = {};
    const uint32_t safe_iterations = iterations > 0 ? static_cast<uint32_t>(iterations) : 42u;

    run_sector(&s, safe_iterations);

    char report[768];
    std::snprintf(
        report,
        sizeof(report),
        "RAFAELOS sector run\n"
        "iterations: %" PRIu32 "\n"
        "hash64: 0x%016" PRIx64 "\n"
        "crc32: 0x%08" PRIx32 "\n"
        "coherence_q16: %" PRIu32 "\n"
        "entropy_q16: %" PRIu32 "\n"
        "last_entropy_milli: %" PRIu32 "\n"
        "last_invariant_milli: %" PRIu32 "\n"
        "spread_milli: %" PRIu32 "\n"
        "output_words: %" PRIu32 "\n"
        "output[0..7]: %" PRIu32 ", %" PRIu32 ", %" PRIu32 ", %" PRIu32 ", %" PRIu32 ", %" PRIu32 ", %" PRIu32 ", %" PRIu32,
        safe_iterations,
        s.hash64,
        s.crc32,
        s.coherence_q16,
        s.entropy_q16,
        s.last_entropy_milli,
        s.last_invariant_milli,
        s.output[7],
        s.output_words,
        s.output[0],
        s.output[1],
        s.output[2],
        s.output[3],
        s.output[4],
        s.output[5],
        s.output[6],
        s.output[7]
    );

    return env->NewStringUTF(report);
}
