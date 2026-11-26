#!/usr/bin/env python3
"""Writes the placeholder sounds no Kenney pack covers into assets/synth/ (plain stdlib, deterministic).

Run from the project root:  python3 tools/audio_synth/synth.py
These are placeholders: replace a file (same name) with a better one any time, nothing else changes.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "assets" / "synth"


def write(name: str, samples: list[float], peak: float = 0.8) -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    top = max(max(abs(s) for s in samples), 1e-9)
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s / top * peak)) * 32767)) for s in samples))
    return path


def env(i: int, n: int, attack: float = 0.004, curve: float = 3.0) -> float:
    """Fast linear attack, then an exponential-ish decay: clean, no clicks."""
    t = i / n
    a = min(1.0, i / max(1, int(attack * RATE)))
    return a * (1.0 - t) ** curve


def tone(freq_from: float, freq_to: float, seconds: float, wave_kind: str = "sine", curve: float = 3.0) -> list[float]:
    n = int(seconds * RATE)
    out: list[float] = []
    phase = 0.0
    for i in range(n):
        f = freq_from + (freq_to - freq_from) * (i / n)
        phase += 2.0 * math.pi * f / RATE
        if wave_kind == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
            s = s * 0.5 + math.sin(phase) * 0.5  # softened so it stays clean, not harsh
        elif wave_kind == "tri":
            s = 2.0 / math.pi * math.asin(math.sin(phase))
        else:
            s = math.sin(phase)
        out.append(s * env(i, n, curve=curve))
    return out


def silence(seconds: float) -> list[float]:
    return [0.0] * int(seconds * RATE)


def noise_burst(seconds: float, low_pass: float, curve: float = 4.0, seed: int = 1) -> list[float]:
    rng = random.Random(seed)
    n = int(seconds * RATE)
    out: list[float] = []
    y = 0.0
    for i in range(n):
        y += (rng.uniform(-1, 1) - y) * low_pass  # one-pole low pass: smaller = duller
        out.append(y * env(i, n, attack=0.001, curve=curve))
    return out


def mix(*parts: list[float]) -> list[float]:
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def wind_loop(seconds: float = 12.0) -> list[float]:
    """Dusty Mars wind: low-passed noise with two slow swells, crossfaded so the loop point is seamless."""
    rng = random.Random(7)
    n = int(seconds * RATE)
    fade = int(1.5 * RATE)
    raw: list[float] = []
    y1 = y2 = 0.0
    for i in range(n + fade):
        t = i / RATE
        w = rng.uniform(-1, 1)
        y1 += (w - y1) * 0.02
        y2 += (w - y2) * 0.12
        swell = 0.55 + 0.30 * math.sin(2 * math.pi * t / seconds * 2 + 1.0) + 0.15 * math.sin(2 * math.pi * t / seconds * 5)
        raw.append((y1 * 1.6 + y2 * 0.35 * swell) * swell)
    out = raw[:n]
    for i in range(fade):  # blend the tail that overshoots the loop into the start
        k = i / fade
        out[i] = out[i] * k + raw[n + i] * (1.0 - k)
    return out


def noise_loop(seconds: float, low_pass: float, high_pass: float, seed: int) -> list[float]:
    """Steady band-passed noise, its tail crossfaded into its start so the loop point is seamless."""
    rng = random.Random(seed)
    n = int(seconds * RATE)
    fade = int(0.5 * RATE)
    raw: list[float] = []
    y = slow = 0.0
    for _ in range(n + fade):
        y += (rng.uniform(-1, 1) - y) * low_pass
        slow += (y - slow) * high_pass
        raw.append(y - slow)
    out = raw[:n]
    for i in range(fade):  # equal power: two noises that don't match would dip with a straight crossfade
        k = i / fade
        out[i] = out[i] * math.sqrt(k) + raw[n + i] * math.sqrt(1.0 - k)
    return out


def engine_loop(seconds: float = 3.0) -> list[float]:
    """A jet-like drone: low harmonics with a slow beat, a thin turbine whine and a rumble. Every tone fits a whole
    number of cycles into the loop."""
    n = int(seconds * RATE)
    rumble = noise_loop(seconds, 0.03, 0.005, 11)
    scale = 1.0 / max(abs(s) for s in rumble)
    tones = [(55.0, 0.5), (110.0, 0.28), (111.0, 0.2), (165.0, 0.12), (220.0, 0.07), (880.0, 0.025), (883.0, 0.02)]
    return [sum(a * math.sin(2 * math.pi * f * i / RATE) for f, a in tones) + rumble[i] * scale * 0.45 for i in range(n)]


def stall_warning_loop() -> list[float]:
    """One beep and its gap."""
    n = int(0.09 * RATE)
    edge = int(0.004 * RATE)
    beep = [math.copysign(0.3, math.sin(2 * math.pi * 950 * i / RATE)) + 0.7 * math.sin(2 * math.pi * 950 * i / RATE)
            for i in range(n)]
    return [s * min(1.0, i / edge, (n - 1 - i) / edge) for i, s in enumerate(beep)] + silence(0.08)


def main() -> None:
    # Order acknowledgements: short, clean, digital. Move rises, attack falls and bites, attack-move does both.
    write("order_move", tone(660, 990, 0.05, "tri") + silence(0.012) + tone(990, 1320, 0.07, "tri"), 0.55)
    write("order_attack", mix(tone(880, 330, 0.12, "square", 2.0), noise_burst(0.05, 0.5, 6.0, 2)), 0.55)
    write("order_attack_move", tone(660, 880, 0.045, "tri") + silence(0.01) + tone(1100, 440, 0.1, "square", 2.0), 0.55)
    write("order_stop", tone(520, 380, 0.09, "tri", 2.0), 0.5)
    # Unit selected in the world: a tiny bright chirp (distinct from the UI ticks).
    write("select_unit", tone(1400, 1900, 0.05, "sine", 2.0), 0.5)
    # Projectile hit: a dry spark.
    write("hit_spark", mix(noise_burst(0.07, 0.6, 5.0, 3), tone(1800, 600, 0.05, "sine", 4.0)), 0.7)
    # Ambient wind.
    write("ambient_mars_wind", wind_loop(), 0.6)
    # The inhabited flight: engine and wind (the game drives their pitch and volume) and the stall warning.
    write("flight_engine", engine_loop(), 0.6)
    write("flight_wind", noise_loop(5.0, 0.22, 0.02, 13), 0.6)
    write("stall_warning", stall_warning_loop(), 0.55)
    print("wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
