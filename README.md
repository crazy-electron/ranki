# RAnki

Minimal flashcard reviewer for Kindle e-reader devices, powered by the real Anki backend.

> ⚠️ **This is beta software.**
> Always backup your Anki collection before using this app.
> I am **not responsible** for any data loss.

---

## What is this?

RAnki is a lightweight reviewer built for Kindle e-readers.  
It uses the real Anki backend (via protobuf, pinned to version **25.09**) so sync and scheduling behave like official Anki.

This is not a reimplementation of Anki’s algorithm.
It talks to the actual backend.

---

## Current Features

- Login (stores a token only — **never your password**)
- Sync decks from AnkiWeb
- Download media (⚠️ see warning below)
- Review cards
- Bury cards

---

## Important Warnings

- Sync will download **all media** linked to your decks.  
  If your collection has large images/audio, check your media size first.
- This is experimental software.
- Always keep external backups of your Anki data.

Data is stored at: ```/mnt/us/anki_data```

---

## Usage

Grab the zip (`ranki.zip`), unpack on `/mnt/us/extensions` as any other extension:

Launch via KUAL and/or copy the shortcut (`shortcut_ranki.sh`) to `/mnt/us/documents` so it shows on your library.

---

## Technical Details

- Written in **Vala**
- Uses **WebKitGTK**
- Communicates with the Anki backend using **protobuf**
- Backend version pinned to **25.09**

---

## Why this exists

In 2023, I compiled Anki (v23.12) for ARM.  
It only worked the python module inside an Alpine Linux chroot.

So I built a small PyQt5 reviewer, and used it since then.

This year I tried compiling a recent Anki version directly.  
It’s a massive (and messy) project, dozen of languages, half a thousand of dependencies.  
I decided to build a clean Vala app that talks directly to the rust backend and runs as a proper Kindle application.

---

## Known Limits

- Audio support has **not been tested**.
- Only **normal/basic cards** were tested.
- **Image Occlusion is not supported.**
- The WebKit engine on Kindle devices is **old**. Fancy CSS, modern layout features, or complex card templates may not render correctly.

---

## Ideas

More features can be added. Suggestions are welcome.

---

## Final Note

This is a personal project made to bring real Anki functionality to e-readers. Use carefully.