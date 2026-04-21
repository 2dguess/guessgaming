Profile photo placeholders (512×512 PNG)
=====================================

These are sample images for testing `profiles.avatar_url`.

The app expects an **https://** URL (e.g. Supabase Storage public URL), not a local path.

Steps:
1. Open Supabase Dashboard → Storage → bucket `avatars` (public).
2. Upload one of these PNGs (or use the in-app profile photo picker).
3. Copy the file’s **public URL** and set `avatar_url` on the profile (or let the app save it after upload).

မြန်မာ: ပရိုဖိုင် `avatar_url` မှာ သုံးဖို့ နမူနာပုံများ ဖြစ်ပါတယ်။
အက်ပ်က `https://` လင့်ခ်ပဲ ဖတ်ပါတယ်။ Supabase Storage `avatars` မှာ အပ်လုဒ်လုပ်ပြီး public URL ကို သုံးပါ။

Files:
  avatar_gamer_01.png … avatar_gamer_06.png

Regenerate:  python tools/generate_profile_photo_placeholders.py
