# MacSlap

Slap your MacBook. It reacts.

MacSlap is a free, open-source macOS app that detects when you slap or hit your MacBook and plays a reaction sound. No subscription. No $4.99 price tag. Just download and slap.

I built this because I kept seeing people charge money for this exact idea. So I made a better one and open-sourced it.

---

## 3 Modes

- **Girl Moan** — your Mac has feelings now
- **Greek Swearing** — it curses back at you in Greek
- **Iranian Swearing** — Farsi fury, no translation needed

Switch between modes anytime. Use responsibly. Or don't.

---

## Download

Head to [Releases](https://github.com/Milad1341/macslap/releases) and download `MacSlap.zip`.

After unzipping, **open Terminal** and run:

```bash
xattr -cr ~/Downloads/MacSlap.app
```

Then move it to Applications and open it normally. That's it.

> **Why?** macOS quarantines apps downloaded from the internet. The command above removes the quarantine flag so Gatekeeper won't block it. This is standard for open-source Mac apps that aren't on the App Store.

---

## Build from source

Requires an **Apple Silicon Mac** (M1 or later), **macOS 13+**, and **Xcode Command Line Tools** (`xcode-select --install`).

```bash
git clone https://github.com/Milad1341/macslap.git
cd macslap
chmod +x build-app.sh
./build-app.sh
open MacSlap.app
```

For a quick debug build that launches immediately:

```bash
chmod +x run.sh
./run.sh
```

---

## Why

Someone was charging money for a MacBook slap app. I thought that was funny. So I built one over a weekend, added three chaotic sound modes, and put it here for free.

Life's too short to pay for a slap sound.

---

## License

MIT — do whatever you want with it.
