
/*
Function: buy_ticket
Parameters:
  p_pool_id UUID
  p_user_id UUID

Atomically inserts a ticket for the user,
increments counter, and closes pool when full.
Return columns: ticket_id, pool_id, user_id, ticket_num
*/
CREATE OR REPLACE FUNCTION public.buy_ticket(p_pool_id UUID, p_user_id UUID)
RETURNS TABLE (
    ticket_id BIGINT,
    pool_id UUID,
    user_id UUID,
    ticket_num INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_sold INT;
    required INT;
BEGIN
    -- lock pool row
    SELECT tickets_sold, tickets_required
      INTO current_sold, required
      FROM raffle_pool
     WHERE pool_id = p_pool_id
     FOR UPDATE;

    IF current_sold >= required THEN
        RAISE EXCEPTION 'Pool is full';
    END IF;

    UPDATE raffle_pool
       SET tickets_sold = tickets_sold + 1
     WHERE pool_id = p_pool_id
     RETURNING tickets_sold INTO current_sold;

    INSERT INTO ticket(pool_id, user_id, ticket_num)
         VALUES (p_pool_id, p_user_id, current_sold)
      RETURNING ticket_id, pool_id, user_id, ticket_num
           INTO ticket_id, pool_id, user_id, ticket_num;

    IF current_sold = required THEN
        UPDATE raffle_pool SET state = 'FULL' WHERE pool_id = p_pool_id;
        -- opzionale: NOTIFY per realtime
    END IF;

    RETURN;
END;
$$;
