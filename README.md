# Ranki - Real Anki on Kindle

“Real Anki for e-ink. Not actually rank.”

Minimal flashcard reviewer for Kindle e-reader devices, powered by the real Anki backend.

> **This is beta software.**
> Always backup your Anki collection before trying this app.
> I am **not responsible** for any data loss.

Built for `armel` and `armhf` (tested on 5.14.3, 5.17.1 and 5.18.5)

<img width="300" alt="decks" src="https://github.com/user-attachments/assets/270407e5-4290-4820-9595-b2d072ca9c1e" />
<img width="300" alt="review" src="https://github.com/user-attachments/assets/87803fb1-eb44-40f3-8586-e4db38d3a072" />

---

## What is this?

Ranki is a lightweight reviewer built for Kindle e-readers.  
It uses the Anki backend (via protobuf, pinned to version **25.09.02**) so sync and scheduling behave like official Anki.

This is not a reimplementation of Anki’s algorithm.
It talks to the actual backend.

---

## Current Features

- Login (stores a token only)
- Sync decks
- Download media (see below)
- Review cards
- Bury cards

---

## Important Warnings

- Sync will download **all media** linked to your decks to your Kindle storage.  
  If your collection has large images/audio, check your media size first.

Data is stored at: `/mnt/us/anki_data`

---

## Usage

Grab the zip (`ranki.zip`), unpack on `/mnt/us/extensions` as any other extension:

Launch via KUAL and/or copy the shortcut (`shortcut_ranki.sh`) to `/mnt/us/documents` so it shows on your library.

---

## Technical Details

- Written in **Vala/GTK2**
- Uses **WebKitGTK**
- Communicates with the Anki backend using **protobuf**
- Backend version pinned to **25.09.02**

---

## Custom Kindle Styling

Ranki adds a custom CSS class to the card container: `.kindle`.

Advanced users can use this class inside their Anki card styling to apply [platform-specific adjustments](https://docs.ankiweb.net/templates/styling.html#platform-specific-css).

```css
.kindle .example {
    font-size: 1.2em;
}
```

---

## Troubleshooting

### Text not rendering correctly? Missing characters or emojis?

Ranki uses the fonts available on your Kindle device.  
If your language characters or emojis are not displayed correctly, it usually means the required font is not installed on the device.

You can install custom fonts following the official Anki [*Styling Guide* method](https://docs.ankiweb.net/templates/styling.html#installing-fonts).

> [!IMPORTANT]
> Because of the Kindle’s old WebKitGTK version, **use regular (non-variable) fonts**.

---

## Why this exists

In 2023, I managed to compile Anki (v23.12) for ARM.  
It only worked the python module (wheel) inside an Alpine Linux chroot.

So I built a small PyQt5 reviewer, and used it since then.

This year I tried compiling a recent Anki version directly.  
It’s a ~~messy~~ massive project, dozen of languages, half a thousand of dependencies. 
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

**[Discord thread](https://discordapp.com/channels/1083603487025274911/1477381087335284796)**