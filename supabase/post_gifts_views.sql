-- Post-level gift popularity (sum of gift_items.popularity_points on this post only)
-- + batch totals + owner-only sender list + received-inventory for gift shop.
-- Run after gifts_popularity.sql

CREATE OR REPLACE FUNCTION public.post_gift_totals_for_posts(p_post_ids uuid[])
RETURNS TABLE (post_id uuid, total_popularity bigint, gift_count bigint)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    pg.post_id,
    COALESCE(SUM(gi.popularity_points), 0)::bigint AS total_popularity,
    COUNT(*)::bigint AS gift_count
  FROM public.post_gifts pg
  INNER JOIN public.gift_items gi ON gi.id = pg.gift_item_id
  WHERE pg.post_id = ANY(p_post_ids)
  GROUP BY pg.post_id;
$$;

REVOKE ALL ON FUNCTION public.post_gift_totals_for_posts(uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.post_gift_totals_for_posts(uuid[]) TO authenticated;

COMMENT ON FUNCTION public.post_gift_totals_for_posts IS
  'Per-post sum(popularity_points) and count of gifts; only gifts on that post.';

CREATE OR REPLACE FUNCTION public.list_post_gifts_for_owner(p_post_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner uuid;
BEGIN
  SELECT p.user_id INTO v_owner
  FROM public.posts p
  WHERE p.post_id = p_post_id
    AND COALESCE(p.is_deleted, FALSE) = FALSE;

  IF v_owner IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  IF v_owner <> auth.uid() THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(row_to_json(x))
      FROM (
        SELECT
          pg.created_at,
          pg.sender_id,
          pr.username AS sender_username,
          pr.avatar_url AS sender_avatar_url,
          gi.kind AS gift_kind,
          gi.title AS gift_title,
          gi.popularity_points
        FROM public.post_gifts pg
        INNER JOIN public.profiles pr ON pr.id = pg.sender_id
        INNER JOIN public.gift_items gi ON gi.id = pg.gift_item_id
        WHERE pg.post_id = p_post_id
        ORDER BY pg.created_at DESC
      ) x
    ),
    '[]'::jsonb
  );
END;
$$;

REVOKE ALL ON FUNCTION public.list_post_gifts_for_owner(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_post_gifts_for_owner(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.user_received_gift_inventory()
RETURNS TABLE (
  gift_item_id uuid,
  kind text,
  title text,
  gift_count bigint,
  total_popularity bigint
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    gi.id AS gift_item_id,
    gi.kind,
    gi.title,
    COUNT(*)::bigint AS gift_count,
    COALESCE(SUM(gi.popularity_points), 0)::bigint AS total_popularity
  FROM public.post_gifts pg
  INNER JOIN public.posts p ON p.post_id = pg.post_id
  INNER JOIN public.gift_items gi ON gi.id = pg.gift_item_id
  WHERE p.user_id = auth.uid()
    AND COALESCE(p.is_deleted, FALSE) = FALSE
  GROUP BY gi.id, gi.kind, gi.title, gi.sort_order
  ORDER BY gi.sort_order ASC, gi.title ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.user_received_gift_inventory() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.user_received_gift_inventory() TO authenticated;
