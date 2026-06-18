# Corne keyboard caps lock hyperkey issue with Raycast

**Session ID:** ses_127d8cd7fffeUGD5RKByWE5Jc3
**Created:** 6/17/2026, 5:35:08 PM
**Updated:** 6/17/2026, 5:44:32 PM

---

## User

I have a Corne v4 keyboard that connects the two halves via a TRS cable. I also use raycast with the hyperkey functionality set to use `caps lock`. Sometimes (often when my phone gets too close to the keyboard, but sometimes without this trigger), raycast will stop recognizing my Corne's `caps lock` press as the hyper key but rather as a defautl caps lock. When this happens, the caps lock key on my macbook still triggers the hyper key functionality correctly. What might be happening, and is this just a bug with the Corne firmware?

---

## Assistant

This is unlikely to be “just a Corne firmware bug.” It sounds more like macOS/Raycast is treating the Corne as a separate keyboard device whose Caps Lock state or modifier mapping gets out of sync.

What may be happening:

- Raycast’s Hyper Key feature probably hooks the built-in keyboard’s `caps lock` behavior reliably, but the Corne presents as a separate HID keyboard.
- When the Corne disconnects/reconnects, glitches, or briefly resets, macOS may reinitialize that keyboard’s Caps Lock behavior differently.
- TRS-connected split keyboards can be electrically noisy if the cable/connection is marginal. Movement, EMI, or static could cause a half reset or communication hiccup.
- A nearby phone can plausibly trigger interference or power/ground noise symptoms, especially if the keyboard/cable/USB path is sensitive.
- Caps Lock is special on macOS. It is not just a normal key; it has OS-level state and per-device handling. That makes it more fragile than using a normal modifier key.

Why the MacBook Caps Lock still works:

- macOS sees the built-in keyboard and the Corne as different keyboard devices.
- Raycast may still be correctly intercepting Caps Lock from the MacBook keyboard while the Corne’s Caps Lock is being interpreted by macOS normally.
- This points away from a global Raycast failure and toward a per-device HID/remapping/state issue.

Things to try:

1. Unplug/replug the Corne when it happens.
   If that fixes it, the Corne or macOS device state is getting confused.

2. Check macOS Keyboard Modifier Keys.
   Go to System Settings → Keyboard → Keyboard Shortcuts / Modifier Keys and confirm the Corne’s Caps Lock mapping has not changed for that specific keyboard.

3. Avoid sending real `Caps Lock` from the Corne.
   In the Corne firmware, map that key to a dedicated modifier combo instead, e.g. `Ctrl+Alt+Cmd+Shift`, or to `F18/F19`, then configure Raycast around that if possible.

4. If using QMK/Vial/VIA, implement Hyper in firmware.
   Instead of relying on Raycast to transform Caps Lock into Hyper, make the Corne key send Hyper directly:
   ```c
   LGUI(LALT(LCTL(LSFT(KC_NO))))
   ```
   or a proper custom keycode/tap-hold depending on your layout.

5. Try another TRS cable.
   A flaky TRS cable or connector can cause intermittent split communication issues. Also make sure you are using TRS, not TRRS, if the board specifically expects TRS.

6. Keep phones away and test.
   If proximity reliably triggers it, that suggests electrical/interference sensitivity, not purely software.

7. Check whether the keyboard resets.
   If RGB, OLED, layer state, or connection behavior changes when the issue appears, the Corne may be browning out or briefly reconnecting.

My guess: the Corne is intermittently reconnecting or presenting Caps Lock in a way that causes macOS/Raycast’s per-device Caps Lock interception to fall back to normal Caps Lock. The best fix is usually to stop using a real `Caps Lock` keycode from the Corne and instead make the keyboard firmware send the actual Hyper modifier combo or a non-Caps key that Raycast binds to.

---

## User

It is fixed by unplugging and re-plugging the keyboard. I think mapping in Vial to hyper would work, but I also use Raycasts Functionality of tapping caps lock to trigger escape.Is there a way to map a single key in vial to be tap on escape but hold for hyper?

---

## Assistant

Yes. In Vial/QMK this is exactly a **mod-tap** key:

- Tap: `Esc`
- Hold: Hyper = `Ctrl + Shift + Alt + Cmd`

In Vial, look for **Quantum** / **Mod Tap** keys and use a key like:

```text
MT(MOD_HYPR, KC_ESC)
```

or equivalently:

```text
MT(MOD_LCTL | MOD_LSFT | MOD_LALT | MOD_LGUI, KC_ESC)
```

Depending on Vial’s UI, it may be shown as something like:

```text
LCTL_T(KC_ESC)
```

but with all four modifiers selected.

Important detail: QMK has a built-in Hyper modifier alias:

```c
MOD_HYPR
```

So the firmware-side keycode would be:

```c
MT(MOD_HYPR, KC_ESC)
```

Behavior:

- Tap key quickly: sends `Escape`
- Hold key: acts as Hyper
- Hold + another key: sends `Ctrl+Shift+Alt+Cmd+that key`

This is probably better than using Raycast’s Caps Lock Hyper feature for your Corne, because the keyboard will no longer emit real `Caps Lock` at all. That avoids the macOS/Raycast per-device Caps Lock weirdness you’re seeing.

One caveat: if Vial’s GUI does not expose arbitrary `MT(MOD_HYPR, KC_ESC)`, use the **Any** key field and enter:

```text
MT(MOD_HYPR, KC_ESC)
```

If that does not compile/apply, try:

```text
MT(MOD_LCTL | MOD_LSFT | MOD_LALT | MOD_LGUI, KC_ESC)
```

---

