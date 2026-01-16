# Investigate: Embedding Asciinema Recordings in Documentation

## Status: ✅ COMPLETE

**Goal**: Determine the best way to embed terminal session recordings in markdown documentation for GitHub

**Last Updated**: 2026-01-15

**Context**: We have an asciinema recording showing Claude Code implementing a plan. We want to include this in documentation about "Developing with AI".

**Result**: GIF conversion works well. A 12MB cast file converts to 7.9MB GIF at 4x speed - easily embeddable on GitHub.

---

## Questions to Answer

1. How can we embed asciinema recordings in GitHub markdown?
2. What will a GIF conversion look like (quality, file size)?
3. What are the limitations of each approach?
4. Which option is best for our use case?

---

## Recording Details

```
File: claudecode-newtool-plan.cast
Size: 12MB
Lines: ~14,670
Format: asciicast v3 (JSON-based, relative timestamps)
Terminal: 94x37, xterm-256color
Duration: 12.9 minutes (776 seconds)
Content: Claude Code session implementing bash dev tools
```

---

## Option A: Upload to asciinema.org + SVG Link

Upload the recording to asciinema.org and embed a clickable SVG preview.

```markdown
[![asciicast](https://asciinema.org/a/YOUR_ID.svg)](https://asciinema.org/a/YOUR_ID)
```

**How it looks:**
- Displays as a static terminal screenshot with a play button
- Clicking opens the asciinema.org player (interactive)
- SVG scales perfectly on all screen sizes

**Pros:**
- Interactive playback (pause, seek, copy text)
- No file size concerns for GitHub repo
- Professional looking SVG preview
- Free hosting on asciinema.org
- Supports themes, speed adjustment, timestamps

**Cons:**
- Requires external dependency (asciinema.org)
- Users must leave the page to watch
- Account required to upload (can be anonymous)
- Recording is public unless you pay

**Upload command:**
```bash
asciinema upload claudecode-newtool-plan.cast
```

---

## Option B: Convert to GIF with `agg`

Convert the .cast file to an animated GIF that plays inline.

```markdown
![Demo](path/to/recording.gif)
```

**How it looks:**
- Animated GIF plays automatically inline
- Loops continuously
- No interaction (can't pause, seek, or copy)

**Pros:**
- Plays inline in markdown (no external site)
- Works everywhere (GitHub, any markdown viewer)
- No external dependencies
- Self-contained in repo

**Cons:**
- **File size**: Large recordings produce large GIFs
  - Our 12MB cast → 7.9MB GIF at 4x speed ✅
  - GitHub has 100MB file limit
  - Very long recordings (30+ min) may exceed limits
- No interactivity (can't pause, seek, copy text)
- Quality vs size tradeoff
- Requires `agg` tool (easy install: `brew install agg`)

**Tools needed:**
```bash
# Install agg
brew install agg
# or
cargo install --git https://github.com/asciinema/agg

# Convert
agg claudecode-newtool-plan.cast output.gif

# Optimize (reduce file size)
brew install gifsicle
gifsicle --lossy=80 -k 128 -O2 output.gif -o output-optimized.gif
```

**File size results:**
From asciinema docs: "GIF encoder produces great looking files, although this often comes at a cost - file size."

For our 12MB, 14.7k-line recording at 4x speed:
- ✅ 7.9MB GIF - well under GitHub's 100MB limit
- ✅ Acceptable load time for documentation
- No trimming needed

---

## Option C: Trim Recording + GIF

Create a shorter highlight clip and convert that to GIF.

**Approach:**
1. Extract key moments from the full recording
2. Create a 30-60 second highlight
3. Convert short clip to GIF

**Pros:**
- Manageable file size
- Quick to watch
- Shows key workflow without full session

**Cons:**
- Loses context of full session
- Requires manual editing
- Additional tooling needed

**Tools:**
```bash
# Trim with asciinema
# (Note: asciinema doesn't have built-in trim, need manual editing or third-party tools)
```

---

## Option D: Host Cast File + JavaScript Player

Self-host the .cast file and use asciinema-player JavaScript library.

```html
<div id="player"></div>
<script src="asciinema-player.min.js"></script>
<script>
  AsciinemaPlayer.create('path/to/recording.cast', document.getElementById('player'));
</script>
```

**Pros:**
- Full interactive player
- No external hosting
- No file size conversion issues

**Cons:**
- **Does NOT work on GitHub** - GitHub strips JavaScript for security
- Only works on custom documentation sites (VuePress, Docusaurus, etc.)
- Requires hosting infrastructure

---

## Option E: Animated SVG

Some tools can generate animated SVG files instead of GIF.

**Pros:**
- Vector format (crisp at any size)
- Can be smaller than GIF
- Works in GitHub markdown

**Cons:**
- `agg` only outputs GIF, not SVG
- Other tools (like `svg-term`) exist but are less maintained
- Browser support for animated SVG varies

---

## Comparison Matrix

| Criteria | asciinema.org | **GIF (4x speed)** ✅ | GIF (trimmed) | JS Player | Animated SVG |
|----------|---------------|----------------------|---------------|-----------|--------------|
| Works on GitHub | Yes (link) | **Yes** | Yes | No | Yes |
| Inline playback | No | **Yes** | Yes | Yes | Yes |
| Interactive | Yes | No | No | Yes | No |
| File size OK | Yes | **Yes (7.9MB)** | Yes | N/A | Maybe |
| No external deps | No | **Yes** | Yes | Yes | Yes |
| Easy to implement | Yes | **Easy** | Hard | Hard | Hard |

**Winner: GIF at 4x speed** - 12MB cast → 7.9MB GIF, plays inline on GitHub

---

## Test Results (2026-01-15)

### GIF Conversion Tests

| Configuration | Output Size | Playback Duration |
|--------------|-------------|-------------------|
| 4x speed | **7.9MB** | ~3.2 minutes |
| 4x speed + idle-time-limit 1s | **7.9MB** | ~3.2 minutes |

**Key findings:**
- Idle time compression made no difference (recording had few long pauses)
- 7.9MB is well under GitHub's 100MB limit
- 7.9MB is well under the 25MB threshold for comfortable inline viewing
- GIF plays at 4x speed for ~3.2 minutes

### Tools Used
```bash
# Install agg (GIF converter)
brew install agg

# Convert to GIF at 4x speed
agg --speed 4 claudecode-newtool-plan.cast demo-4x.gif
```

---

## How to Identify and Extract Highlights

### Step 1: Preview the Recording

```bash
# Play at 4x speed to quickly scan through
asciinema play --speed 4 claudecode-newtool-plan.cast

# Or play with idle time limited (skips long pauses)
asciinema play --idle-time-limit 2 claudecode-newtool-plan.cast
```

**Controls during playback:**
- `Space` - Pause/Resume
- `.` - Step forward (when paused)
- `Ctrl+C` - Stop

**Note the timestamps** of interesting moments as you watch.

### Step 2: Editing Tools

**Option A: asciinema-edit** (recommended)
```bash
# Install via Go
go install github.com/cirocosta/asciinema-edit@latest

# Or download binary from releases
# https://github.com/cirocosta/asciinema-edit/releases
```

Commands:
```bash
# Cut out a time range (remove frames 0-60 seconds)
cat recording.cast | asciinema-edit cut --start=0 --end=60 > trimmed.cast

# Speed up a section
asciinema-edit speed --factor 2 --start=120 --end=180 recording.cast > faster.cast

# Reduce long pauses to max 1 second
asciinema-edit quantize --range 1 recording.cast > no-pauses.cast
```

**Option B: asciinema-trim**
```bash
# Install via Homebrew
brew install suzuki-shunsuke/asciinema-trim/asciinema-trim
```

**Option C: Manual JSON editing**
The .cast file is just JSON - you can manually edit it:
1. Open in text editor
2. Delete lines (events) you don't want
3. Adjust timestamps as needed

### Step 3: Suggested Highlight Strategy

For a long recording, consider creating:

1. **Quick demo (30-60 seconds)**
   - Start: Launching Claude Code
   - Middle: One phase being executed (shows tool use)
   - End: Completion message

2. **Full workflow summary (2-3 minutes)**
   - Intro: Giving Claude the plan
   - Speed up: Claude reading and setting up
   - Normal speed: Key interactions (user input, phase transitions)
   - Speed up: Repetitive work
   - End: Final commit

### Step 4: Create the Highlight

```bash
# Example workflow to create a 60-second highlight:

# 1. Remove first 30 seconds (session setup)
cat claudecode-newtool-plan.cast | asciinema-edit cut --start=0 --end=30 > step1.cast

# 2. Keep only seconds 30-90 (first interesting phase)
cat step1.cast | asciinema-edit cut --start=60 --end=2100 > step2.cast

# 3. Speed up any slow parts
asciinema-edit speed --factor 2 step2.cast > highlight.cast

# 4. Reduce pauses
asciinema-edit quantize --range 1 highlight.cast > highlight-final.cast

# 5. Convert to GIF
agg highlight-final.cast highlight.gif
```

---

## Investigation Tasks

- [x] Install `agg` for GIF conversion: `brew install agg`
- [ ] ~~Install `asciinema-edit` for trimming~~ (not needed - GIF size is acceptable)
- [x] Test GIF conversion on smaller recording:
  ```bash
  agg --speed 4 claudecode-newtool-plan.cast demo.gif
  ls -lh demo.gif  # Check file size → 7.9MB ✅
  ```
- [x] Test with idle time limit (no difference - 7.9MB)
- [ ] ~~Test upload to asciinema.org~~ (not needed - GIF approach works)
- [x] Decide: **GIF (inline)** - file size is acceptable
- [ ] Create `docs/developing-with-ai.md` with embedded recording

---

## Final Recommendation

**Use GIF conversion** with the following settings:

```bash
agg --speed 4 claudecode-newtool-plan.cast demo-4x.gif
```

**Result:** 7.9MB GIF, ~3.2 min playback - perfect for inline embedding.

**For future recordings:**
- Keep recordings under 15 minutes for GIF feasibility
- Use 4x speed for reasonable playback duration
- Expect roughly 60-70% compression from cast → GIF at 4x speed

---

## Next Steps

1. ~~Test GIF conversion~~ ✅ Complete
2. Move `demo-4x.gif` to `docs/assets/` or similar
3. Create `docs/developing-with-ai.md` with embedded GIF
4. Clean up: delete `.cast` source file and duplicate GIFs

---

## Sources

- [asciinema Embedding Documentation](https://docs.asciinema.org/manual/server/embedding/)
- [agg - asciinema gif generator](https://docs.asciinema.org/manual/agg/)
- [GitHub asciinema/agg](https://github.com/asciinema/agg)
- [Enhance Your Readme With Asciinema](https://www.cesarsotovalero.net/blog/enhance-your-readme-with-asciinema.html)
