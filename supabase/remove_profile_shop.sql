-- Remove profile-frame shop (run once on a DB that had shop_profile_frames.sql applied).
-- Order: functions → purchases table → profile FK column → catalog table.

DROP FUNCTION IF EXISTS public.equip_profile_shop_item(uuid);
DROP FUNCTION IF EXISTS public.purchase_shop_item(uuid);

DROP TABLE IF EXISTS public.user_shop_purchases;

ALTER TABLE public.profiles
  DROP COLUMN IF EXISTS equipped_shop_item_id;

DROP TABLE IF EXISTS public.shop_items;
