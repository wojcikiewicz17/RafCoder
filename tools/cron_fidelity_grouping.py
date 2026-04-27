#!/usr/bin/env python3
"""CRON Fidelity Groups benchmark (low-level, no heavy deps).

Implements a practical approximation of the user's 50-equation framework:
- maps each sector to T^7 coordinates
- updates coherence/entropy with alpha=0.25
- computes a coherent geometric invariant I
- groups 40 sectors into 5 benchmark layers

Usage:
  python tools/cron_fidelity_grouping.py --iterations 1000 --seed 42
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import zlib
from dataclasses import dataclass
from statistics import median
from typing import Dict, List, Sequence, Tuple

T7Point = Tuple[float, float, float, float, float, float, float]

ALPHA = 0.25
VOID_THRESHOLD = 0.9
TWO_PI = 2.0 * math.pi

GROUPS = [
    ("Ω", "Orquestração Quântica", 0.90, 1.01),
    ("Δ", "Diferenciação Fractal", 0.70, 0.90),
    ("Σ", "Sintropia Coerente", 0.50, 0.70),
    ("Π", "Pseudo-Caos Entrópico", 0.25, 0.50),
    ("Ξ", "Exponencial Linguística", 0.00, 0.25),
]


@dataclass
class SectorResult:
    sector_id: int
    median_R: float
    median_I: float
    neon_frequency: float
    median_entropy: float
    group_code: str
    group_name: str


def clamp01(x: float) -> float:
    return 0.0 if x < 0.0 else (1.0 if x > 1.0 else x)


def toroidal_map(data: int, entropy: float, h: int, state: int) -> T7Point:
    """Eq. 1..4 and 45: map x=(dados, entropia, hash, estado) into [0,1)^7."""
    digest = hashlib.sha256(f"{data}|{entropy:.9f}|{h}|{state}".encode()).digest()
    parts = [int.from_bytes(digest[i : i + 4], "little") / 2**32 for i in range(0, 28, 4)]
    # Preserve one dimension as direct entropy projection.
    parts[1] = entropy % 1.0
    return tuple(parts)  # type: ignore[return-value]


def entropy_milli(byte_seq: Sequence[int]) -> float:
    """Eq. 43 scaled to [0,1] for composability."""
    if not byte_seq:
        return 0.0
    unique = len(set(byte_seq))
    transitions = sum(1 for a, b in zip(byte_seq, byte_seq[1:]) if a != b)
    if len(byte_seq) == 1:
        raw = (unique * 6000.0) / 256.0
    else:
        raw = (unique * 6000.0) / 256.0 + (transitions * 2000.0) / (len(byte_seq) - 1)
    return clamp01(raw / 8000.0)


def coherence_update(c_t: float, c_in: float, h_t: float, h_in: float) -> Tuple[float, float]:
    """Eq. 5..7"""
    c_next = (1.0 - ALPHA) * c_t + ALPHA * c_in
    h_next = (1.0 - ALPHA) * h_t + ALPHA * h_in
    return c_next, h_next


def cardioid_resonance(spectrum: Sequence[float], cardioid: Sequence[float]) -> float:
    """Eq. 12 and 44."""
    dot = sum(a * b for a, b in zip(spectrum, cardioid))
    norm_s = math.sqrt(sum(a * a for a in spectrum))
    norm_c = math.sqrt(sum(b * b for b in cardioid))
    if norm_s == 0.0 or norm_c == 0.0:
        return 0.0
    return clamp01((dot / (norm_s * norm_c) + 1.0) * 0.5)


def geometric_invariant(s: T7Point, R: float, H: float, C: float, geom_bits: float) -> float:
    """Eq. 50 practical form: I = Phi(s,S,H,C,G)."""
    spread = sum(abs(s[i] - s[(i + 1) % 7]) for i in range(7)) / 7.0
    phi = (1.0 - H) * C  # Eq. 8
    base = 0.35 * R + 0.30 * phi + 0.20 * (1.0 - spread) + 0.15 * clamp01(geom_bits / 8.0)
    return clamp01(base)


def fnv_step(h: int, byte: int) -> int:
    """Eq. 31/32 style step."""
    h ^= byte
    h = (h * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return h


def run_sector(sector_id: int, iterations: int, seed: int) -> SectorResult:
    rng = random.Random(seed + sector_id * 997)
    c_t = 0.5
    h_t = 0.5
    h64 = 0xCBF29CE484222325

    R_values: List[float] = []
    I_values: List[float] = []
    ent_values: List[float] = []
    neon_hits = 0

    for step in range(iterations):
        payload = [rng.randrange(0, 256) for _ in range(32)]
        ent = entropy_milli(payload)
        ent_values.append(ent)

        for b in payload:
            h64 = fnv_step(h64, b)

        crc = zlib.crc32(bytes(payload)) & 0xFFFFFFFF
        c_in = ((h64 ^ crc) & 0xFFFF) / 0xFFFF
        h_in = clamp01(ent)
        c_t, h_t = coherence_update(c_t, c_in, h_t, h_in)

        # Spectral proxy (minimal CPU): 7 harmonics from torus projection.
        s = toroidal_map(sum(payload), h_t, h64, step % 42)
        spectrum = [math.sin(TWO_PI * x) for x in s]
        cardioid = [math.cos(TWO_PI * x) for x in s]
        R = cardioid_resonance(spectrum, cardioid)

        M, N = 8, 8
        geom_bits = math.log2(M * N)  # Eq. 46
        I = geometric_invariant(s, R, h_t, c_t, geom_bits)

        R_values.append(R)
        I_values.append(I)

        if I > VOID_THRESHOLD:
            neon_hits += 1

    med_R = median(R_values)
    med_I = median(I_values)
    med_entropy = median(ent_values)
    neon_frequency = neon_hits / float(iterations)

    for code, name, lo, hi in GROUPS:
        if lo <= med_I < hi:
            return SectorResult(sector_id, med_R, med_I, neon_frequency, med_entropy, code, name)
    code, name, _, _ = GROUPS[-1]
    return SectorResult(sector_id, med_R, med_I, neon_frequency, med_entropy, code, name)


def run_benchmark(iterations: int, seed: int) -> Dict[str, object]:
    results = [run_sector(i, iterations, seed) for i in range(1, 41)]
    summary: Dict[str, Dict[str, object]] = {}

    for r in results:
        bucket = summary.setdefault(
            r.group_code,
            {
                "name": r.group_name,
                "count": 0,
                "sectors": [],
                "median_R": [],
                "median_I": [],
                "neon_frequency": [],
            },
        )
        bucket["count"] = int(bucket["count"]) + 1
        bucket["sectors"].append(r.sector_id)
        bucket["median_R"].append(r.median_R)
        bucket["median_I"].append(r.median_I)
        bucket["neon_frequency"].append(r.neon_frequency)

    for bucket in summary.values():
        bucket["median_R"] = round(median(bucket["median_R"]), 6)
        bucket["median_I"] = round(median(bucket["median_I"]), 6)
        bucket["neon_frequency"] = round(median(bucket["neon_frequency"]), 6)
        bucket["sectors"] = sorted(bucket["sectors"])

    return {
        "config": {"iterations": iterations, "seed": seed, "alpha": ALPHA, "void_threshold": VOID_THRESHOLD},
        "sectors": [r.__dict__ for r in results],
        "groups": summary,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="CRON Fidelity benchmark for 40 sectors")
    parser.add_argument("--iterations", type=int, default=1000, help="Iterations per sector")
    parser.add_argument("--seed", type=int, default=42, help="Deterministic seed")
    parser.add_argument("--output", type=str, default="", help="Optional JSON output path")
    args = parser.parse_args()

    report = run_benchmark(args.iterations, args.seed)
    text = json.dumps(report, ensure_ascii=False, indent=2)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        print(text)


if __name__ == "__main__":
    main()
