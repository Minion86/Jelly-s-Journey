#!/usr/bin/env python3
"""Generate the original Jelly leitmotif score and game SFX.

The score uses synthesis and composition rules written for this project. It does
not sample, transcribe, or reproduce music from the gameplay references.
"""

from __future__ import annotations

import math
import os
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MUSIC_DIR = ROOT / "audio" / "music"
SFX_DIR = ROOT / "audio" / "sfx"
SR = 44_100

LEVELS = [
    ("ny-taxi", 154, 62, "square", "city", [0, 4, 5, 3]),
    ("ny-park", 126, 65, "triangle", "light", [0, 3, 4, 0]),
    ("ny-bridge", 142, 60, "pulse", "march", [0, 5, 3, 4]),
    ("la-boardwalk", 148, 64, "pulse", "surf", [0, 4, 3, 5]),
    ("la-studio", 132, 57, "square", "cinema", [0, 5, 2, 4]),
    ("la-sunset", 116, 69, "triangle", "surf", [0, 3, 5, 4]),
    ("la-jazz", 138, 58, "reed", "swing", [0, 3, 4, 1]),
    ("la-bayou", 108, 55, "triangle", "night", [0, 5, 3, 4]),
    ("la-riverboat", 144, 60, "reed", "swing", [0, 4, 1, 5]),
    ("or-grove", 150, 67, "pluck", "grove", [0, 4, 5, 3]),
    ("or-lake", 122, 62, "bell", "water", [0, 3, 4, 0]),
    ("or-home", 136, 65, "square", "home", [0, 5, 3, 4]),
]

# An original eight-note identity used as a family resemblance between cues.
JELLY_MOTIF = [0, 4, 7, 9, 7, 4, 2, 6]
MAJOR = [0, 2, 4, 5, 7, 9, 11]


def midi(note: float) -> float:
    return 440.0 * 2.0 ** ((note - 69.0) / 12.0)


def oscillator(kind: str, phase: np.ndarray) -> np.ndarray:
    cycle = phase / (2.0 * np.pi)
    if kind == "square":
        return np.sign(np.sin(phase)) * 0.82
    if kind == "pulse":
        return np.where((cycle % 1.0) < 0.32, 0.9, -0.75)
    if kind == "triangle":
        return 2.0 * np.abs(2.0 * (cycle % 1.0) - 1.0) - 1.0
    if kind == "reed":
        return 0.62 * np.sin(phase) + 0.25 * np.sin(2 * phase) + 0.13 * np.sin(3 * phase)
    if kind == "bell":
        return 0.62 * np.sin(phase) + 0.25 * np.sin(2.01 * phase) + 0.13 * np.sin(3.98 * phase)
    if kind == "pluck":
        return 0.68 * np.sin(phase) + 0.22 * np.sin(2 * phase) + 0.1 * np.sin(5 * phase)
    return np.sin(phase)


def add_note(
    mix: np.ndarray,
    start: float,
    duration: float,
    note: float,
    amplitude: float,
    kind: str,
    pan: float = 0.0,
    attack: float = 0.01,
    release: float = 0.08,
    vibrato: float = 0.0,
) -> None:
    start_i = max(0, int(start * SR))
    count = min(int(duration * SR), len(mix) - start_i)
    if count <= 0:
        return
    t = np.arange(count, dtype=np.float64) / SR
    freq = midi(note)
    phase = 2.0 * np.pi * freq * t
    if vibrato:
        phase += vibrato * np.sin(2.0 * np.pi * 5.1 * t)
    tone = oscillator(kind, phase)
    envelope = np.ones(count)
    attack_n = min(count, max(1, int(attack * SR)))
    release_n = min(count, max(1, int(release * SR)))
    envelope[:attack_n] = np.linspace(0.0, 1.0, attack_n)
    envelope[-release_n:] *= np.linspace(1.0, 0.0, release_n)
    if kind in {"pluck", "bell"}:
        envelope *= np.exp(-t * (3.1 if kind == "pluck" else 1.7))
    signal = tone * envelope * amplitude
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    mix[start_i:start_i + count, 0] += signal * left
    mix[start_i:start_i + count, 1] += signal * right


def add_kick(mix: np.ndarray, start: float, amplitude: float = 0.28) -> None:
    count = int(0.19 * SR)
    start_i = int(start * SR)
    count = min(count, len(mix) - start_i)
    if count <= 0:
        return
    t = np.arange(count) / SR
    phase = 2 * np.pi * (92 * t - 36 * t * t)
    sig = np.sin(phase) * np.exp(-t * 22) * amplitude
    mix[start_i:start_i + count] += sig[:, None]


def add_noise_hit(mix: np.ndarray, start: float, rng: np.random.Generator, bright: bool, amplitude: float) -> None:
    duration = 0.08 if bright else 0.16
    count = int(duration * SR)
    start_i = int(start * SR)
    count = min(count, len(mix) - start_i)
    if count <= 2:
        return
    t = np.arange(count) / SR
    noise = rng.normal(0, 1, count)
    if bright:
        noise = np.concatenate(([0.0], np.diff(noise)))
    else:
        kernel = np.ones(9) / 9
        noise = np.convolve(noise, kernel, mode="same")
    sig = noise * np.exp(-t * (46 if bright else 22)) * amplitude
    mix[start_i:start_i + count, 0] += sig * 0.72
    mix[start_i:start_i + count, 1] += sig * 0.72


def compose_track(level_id: str, bpm: int, key: int, lead: str, feel: str, progression: list[int]) -> np.ndarray:
    beat = 60.0 / bpm
    bars = 16
    duration = bars * 4 * beat
    mix = np.zeros((int(duration * SR), 2), dtype=np.float64)
    rng = np.random.default_rng(abs(hash(level_id)) % (2**32))
    swing = 0.11 * beat if feel == "swing" else 0.0

    for bar in range(bars):
        degree = progression[bar % len(progression)]
        chord_root = key + MAJOR[degree % 7]
        chord = [chord_root, chord_root + 4, chord_root + 7]
        bar_start = bar * 4 * beat

        # Bass line changes shape by location while keeping strong landing beats.
        for step in range(8):
            when = bar_start + step * 0.5 * beat + (swing if step % 2 else 0.0)
            bass_note = chord_root - 24 + ([0, 0, 7, 0, 12, 7, 4, 7][step] if feel != "night" else [0, 7, 0, 4, 0, 7, 3, 7][step])
            add_note(mix, when, 0.42 * beat, bass_note, 0.105, "triangle", -0.1, 0.008, 0.055)

        # Soft chord punctuation; each chapter gets a slightly different color.
        chord_kind = "pulse" if feel in {"city", "cinema", "march"} else "pluck" if feel in {"grove", "water"} else "reed"
        for pulse in range(4):
            when = bar_start + pulse * beat
            for voice, chord_note in enumerate(chord):
                add_note(mix, when, 0.31 * beat, chord_note - 12, 0.032, chord_kind, -0.35 + voice * 0.35, 0.006, 0.05)

        # Jelly motif. B section inverts and lifts it so the loop tells a small story.
        motif = JELLY_MOTIF if bar < 8 else [9 - value for value in JELLY_MOTIF]
        rotation = bar % len(motif)
        for step in range(8):
            when = bar_start + step * 0.5 * beat + (swing if step % 2 else 0.0)
            interval = motif[(step + rotation) % len(motif)]
            passing = 12 if bar in {7, 15} and step >= 6 else 0
            add_note(mix, when, 0.38 * beat, key + interval + passing, 0.12, lead, 0.18, 0.012, 0.075, 0.035 if lead == "reed" else 0.0)

        # Countermelody and environmental sparkle.
        for step in range(4):
            when = bar_start + (step + 0.5) * beat
            counter_note = chord[(step + bar) % 3] + 12
            add_note(mix, when, 0.24 * beat, counter_note, 0.042, "bell" if feel in {"night", "water", "home"} else "pluck", -0.48, 0.003, 0.08)

        for beat_i in range(4):
            when = bar_start + beat_i * beat
            add_kick(mix, when, 0.22 if feel != "light" else 0.15)
            if beat_i in {1, 3}:
                add_noise_hit(mix, when, rng, False, 0.05 if feel == "night" else 0.075)
            add_noise_hit(mix, when + 0.5 * beat, rng, True, 0.018 if feel in {"night", "water"} else 0.026)

        if feel in {"city", "march"}:
            add_note(mix, bar_start + 3.5 * beat, 0.18 * beat, key + 24, 0.055, "bell", 0.6, 0.003, 0.05)
        elif feel == "surf":
            for step in range(8):
                add_note(mix, bar_start + step * 0.5 * beat, 0.16 * beat, chord[step % 3] + 12, 0.027, "triangle", 0.55, 0.003, 0.025)

    # Short crossfade-compatible tail and safe limiter.
    fade = min(int(0.06 * SR), len(mix) // 8)
    mix[:fade] *= np.linspace(0, 1, fade)[:, None]
    mix[-fade:] *= np.linspace(1, 0, fade)[:, None]
    peak = max(1.0, np.max(np.abs(mix)) / 0.93)
    return np.tanh(mix / peak * 1.22) * 0.82


def write_wav(path: Path, signal: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.int16(np.clip(signal, -1, 1) * 32767)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2 if pcm.ndim == 2 else 1)
        output.setsampwidth(2)
        output.setframerate(SR)
        output.writeframes(pcm.tobytes())


def encode_ogg(wav_path: Path, ogg_path: Path, quality: int = 4) -> None:
    ogg_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(wav_path),
        "-c:a", "libvorbis", "-q:a", str(quality), str(ogg_path),
    ], check=True)


def bark_variant(seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    duration = 0.58 + seed * 0.025
    count = int(duration * SR)
    t = np.arange(count) / SR
    signal = np.zeros(count)
    for offset, pitch, gain in [(0.03, 176 - seed * 7, 0.78), (0.235, 143 + seed * 4, 0.62)]:
        local = t - offset
        gate = (local >= 0) & (local < 0.19)
        lt = np.maximum(local, 0)
        noise = rng.normal(0, 1, count)
        formant = np.sin(2 * np.pi * pitch * lt + 6.5 * np.sin(2 * np.pi * 19 * lt))
        rough = np.tanh(formant * 1.8 + noise * 0.48)
        envelope = np.exp(-lt * 15) * (1 - np.exp(-lt * 90))
        signal += gate * rough * envelope * gain
    signal = np.tanh(signal * 1.4) * 0.8
    return np.column_stack((signal * 0.94, signal))


def tone_sfx(kind: str) -> np.ndarray:
    rng = np.random.default_rng(sum(map(ord, kind)))
    durations = {"jump": .34, "land": .22, "treat": .42, "checkpoint": .8, "hurt": .5, "squirrel": .52, "win": 1.5, "whoosh": .38}
    duration = durations[kind]
    count = int(duration * SR)
    t = np.arange(count) / SR
    mono = np.zeros(count)
    if kind == "jump":
        phase = 2 * np.pi * (330 * t + 520 * t * t)
        mono = np.sin(phase) * np.exp(-t * 6.5) * .55
    elif kind == "land":
        mono = (np.sin(2 * np.pi * 72 * t) + rng.normal(0, .34, count)) * np.exp(-t * 25) * .44
    elif kind == "whoosh":
        noise = rng.normal(0, 1, count)
        mono = np.concatenate(([0], np.diff(noise))) * np.sin(np.pi * t / duration) * .12
    elif kind == "hurt":
        mono = (np.sin(2*np.pi*(420*t - 250*t*t)) + .35*np.sign(np.sin(2*np.pi*210*t))) * np.exp(-t*6.5) * .34
    elif kind == "squirrel":
        for offset, freq in [(0.02, 1220), (.14, 1480), (.29, 1110)]:
            local = np.maximum(t-offset, 0)
            mono += (t >= offset) * np.sin(2*np.pi*(freq*local + 210*local*local)) * np.exp(-local*24) * .23
    else:
        notes = [72, 76, 79, 84] if kind in {"checkpoint", "win"} else [79, 83, 86]
        spacing = .14 if kind == "treat" else .21
        for i, note in enumerate(notes):
            local = np.maximum(t-i*spacing, 0)
            mono += (t >= i*spacing) * (np.sin(2*np.pi*midi(note)*local) + .25*np.sin(4*np.pi*midi(note)*local)) * np.exp(-local*7.5) * .2
    mono = np.tanh(mono * 1.35) * .8
    return np.column_stack((mono, mono))


def main() -> None:
    MUSIC_DIR.mkdir(parents=True, exist_ok=True)
    SFX_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="jelly-audio-") as temp:
        temp_dir = Path(temp)
        for spec in LEVELS:
            level_id = spec[0]
            wav = temp_dir / f"{level_id}.wav"
            write_wav(wav, compose_track(*spec))
            encode_ogg(wav, MUSIC_DIR / f"{level_id}.ogg", 4)
            print(f"music: {level_id}")
        for index in range(1, 4):
            wav = temp_dir / f"bark_{index}.wav"
            write_wav(wav, bark_variant(index))
            encode_ogg(wav, SFX_DIR / f"bark_{index}.ogg", 5)
        for name in ["jump", "land", "treat", "checkpoint", "hurt", "squirrel", "win", "whoosh"]:
            wav = temp_dir / f"{name}.wav"
            write_wav(wav, tone_sfx(name))
            encode_ogg(wav, SFX_DIR / f"{name}.ogg", 5)
            print(f"sfx: {name}")


if __name__ == "__main__":
    main()

