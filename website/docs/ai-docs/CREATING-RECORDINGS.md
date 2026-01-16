# Creating Terminal Session Recordings

This document explains how to create terminal session recordings and convert them to GIFs for documentation.

## Overview

We use [asciinema](https://asciinema.org/) to record terminal sessions and [agg](https://github.com/asciinema/agg) to convert them to animated GIFs that can be embedded in markdown documentation.

## Files in This Folder

| File | Description |
|------|-------------|
| `ai-implement-plan.cast` | Source recording (12MB, 12.9 min) |
| `ai-implement-plan.gif` | Full session GIF at 4x speed (7.9MB, ~3.2 min) |
| `ai-implement-plan-teaser.gif` | Short teaser GIF at 3x speed (1.8MB, ~60 sec) |
| `ai-implement-plan-teaser.cast` | Trimmed source for teaser (180 sec) |
| `ai-implement-plan-original.cast` | Backup of original recording |
| `ai-make-plan.png` | Screenshot of planning phase |

---

## Step 1: Install Tools

```bash
# Install asciinema (for recording)
brew install asciinema

# Install agg (for GIF conversion)
brew install agg
```

---

## Step 2: Record a Terminal Session

```bash
# Start recording
asciinema rec my-session.cast

# Do your work in the terminal...
# Press Ctrl+D or type 'exit' to stop recording
```

**Tips for good recordings:**
- Keep recordings under 15 minutes for reasonable GIF sizes
- Use a clean terminal with good contrast
- Avoid long idle periods (or they'll be compressed anyway)

**Check recording details:**
```bash
# View recording info
asciinema play my-session.cast

# Calculate duration (v3 format uses relative timestamps)
python3 -c "
import json
total = sum(json.loads(line)[0] for i, line in enumerate(open('my-session.cast')) if i > 0)
print(f'Duration: {total:.0f}s ({total/60:.1f} min)')
"
```

---

## Step 3: Convert to Full GIF

```bash
# Convert at 4x speed (recommended for long sessions)
agg --speed 4 my-session.cast my-session.gif

# Check file size
ls -lh my-session.gif
```

**Speed recommendations:**
- 2x speed: Easy to follow, but longer playback
- 3x speed: Good balance for medium sessions
- 4x speed: Best for long sessions (10+ minutes)

**Our example:**
```bash
# 12.9 min recording → 3.2 min GIF at 4x speed
agg --speed 4 ai-implement-plan.cast ai-implement-plan.gif
# Result: 7.9MB
```

---

## Step 4: Create a Teaser GIF

For attention-grabbing teasers, extract a shorter segment from the recording.

### 4.1 Trim the Recording

Create a Python script to extract a time range:

```bash
python3 << 'EOF'
import json

cast_file = 'ai-implement-plan.cast'
output_file = 'ai-implement-plan-teaser.cast'

# Extract first N seconds
# For 60-sec teaser at 3x speed, extract 180 seconds
MAX_TIME = 180

with open(cast_file) as f:
    lines = f.readlines()

output_lines = [lines[0]]  # Keep header

cumulative = 0
for line in lines[1:]:
    event = json.loads(line)
    cumulative += event[0]
    if cumulative > MAX_TIME:
        break
    output_lines.append(line)

with open(output_file, 'w') as f:
    f.writelines(output_lines)

print(f'Extracted {len(output_lines)-1} events, ~{cumulative:.1f}s')
EOF
```

### 4.2 Convert Teaser to GIF

```bash
# Convert at 3x speed for ~60 second playback
agg --speed 3 ai-implement-plan-teaser.cast ai-implement-plan-teaser.gif

# Check size
ls -lh ai-implement-plan-teaser.gif
# Result: 1.8MB
```

---

## Teaser Duration Cheat Sheet

| Desired Playback | Speed | Source Duration |
|------------------|-------|-----------------|
| 20 sec | 3x | 60 sec |
| 30 sec | 3x | 90 sec |
| 60 sec | 3x | 180 sec |
| 60 sec | 4x | 240 sec |

Formula: `source_duration = playback_duration × speed`

---

## Embedding in Markdown

```markdown
<!-- Teaser with link to full version -->
[![Watch the full session](ai-implement-plan-teaser.gif)](ai-implement-plan.gif)

<!-- Or just the full GIF -->
![AI implementing a plan](ai-implement-plan.gif)
```

---

## File Size Guidelines

| Cast Size | GIF at 4x | Notes |
|-----------|-----------|-------|
| 12MB | ~8MB | Good for GitHub |
| 25MB | ~15-20MB | Still acceptable |
| 50MB+ | 50MB+ | Consider trimming |

GitHub's file size limit is 100MB. Aim for GIFs under 25MB for good loading performance.

---

## Troubleshooting

### GIF too large?
- Increase speed (4x instead of 3x)
- Trim to shorter segment
- Use `--idle-time-limit 1` to compress pauses

### Recording format issues?
The cast file is JSON. First line is header, subsequent lines are events:
```json
{"version": 3, "term": {"cols": 94, "rows": 37, ...}}
[0.142, "o", "output text"]
[0.050, "o", "more output"]
```

Version 3 uses relative timestamps (delta from previous event).

### Preview before converting?
```bash
# Play at increased speed
asciinema play --speed 4 my-session.cast

# Controls: Space=pause, .=step, Ctrl+C=stop
```
