# Code Review: dim_activity.sql

**Reviewer**: Analytics Engineer
**Author**: Intern
**File**: `dim_activity.sql`
**Date**: Review conducted

---

## Summary

Hi! Thanks for sharing your code. I can see you've put good thought into the business logic and CTE structure. However, there are **several critical performance issues** causing the slow build times you mentioned. The good news is they're all fixable! Below I'll walk through each issue and provide optimized solutions.

## Critical Issues (Performance Killers)

### 1. Correlated Subquery in WHERE Clause (Lines 8)

**Problem**:
```sql
where login_at = (select min(login_at) from login llb where lla.user_id = llb.user_id)
```

This runs a subquery **for every row** in the login table. If you have 1M login records, this executes 1M subqueries!

**Why it's slow**:
- O(n²) complexity - the database scans the entire table for each row
- No index can help here
- This is one of the most expensive query patterns

**Solution**: Use a window function instead:
```sql
signed_up_users as (
    select
        user_id,
        country,
        login_at
    from (
        select
            user_id,
            country,
            login_at,
            row_number() over (partition by user_id order by login_at) as rn
        from login
    )
    where rn = 1
)
```

**Performance gain**: O(n log n) instead of O(n²) - could be **100-1000x faster** on large datasets!

---

### 2. Incorrect Window Function Usage (Lines 15-16, 25-26)

**Problem**:
```sql
min(event_happened_at) over (partition by user_id order by event_happened_at asc) as first_played_at,
row_number() over (partition by user_id order by event_happened_at asc) as r_n
```

**Why it's wrong**:
- `MIN()` with `ORDER BY` in the window creates a **running minimum**, not the overall minimum
- This means every row for a user might get a different value as the window "slides"
- You're then filtering `where r_n = 1`, so you only get one row anyway
- The `MIN()` is doing unnecessary work

**What happens**:
- Row 1 (earliest): `min` = timestamp of row 1 ✓
- Row 2: `min` = timestamp of row 1 (still correct due to ordering)
- But the window function processes ALL rows unnecessarily

**Solution**: Just use `row_number()`, then select the timestamp directly:
```sql
first_song_played as (
    select
        user_id,
        song_name,
        event_happened_at as first_played_at
    from (
        select
            user_id,
            song_name,
            event_happened_at,
            row_number() over (partition by user_id order by event_happened_at asc) as rn
        from song_played
    )
    where rn = 1
)
```

**Same issue in `last_song_played`**:
```sql
last_song_played as (
    select
        user_id,
        song_name,
        event_happened_at as last_played_at
    from (
        select
            user_id,
            song_name,
            event_happened_at,
            row_number() over (partition by user_id order by event_happened_at desc) as rn
        from song_played
    )
    where rn = 1
)
```

**Performance gain**: Eliminates unnecessary window function computation, clearer logic.

---

### 3. Cartesian Join + Correlated Subquery (Lines 40-68) - BIGGEST ISSUE

**Problem**: This is the **major performance killer** in your query.

**Line 52**:
```sql
left join challenge_opened on song_played.user_id = challenge_opened.user_id
```

This creates a **Cartesian product** per user:
- If a user has 100 songs played and 50 challenges opened = **5,000 rows** for that user
- For 10,000 users with similar activity = **50 million rows** in the staging CTE!

**Lines 62-67**: Then you run a **correlated subquery** on this massive dataset:
```sql
and time_diff = (select min(time_diff)
                 from song_played_after_challenge_staging s_b
                 where s_a.user_id = s_b.user_id
                   and s_a.song_event_id = s_b.song_event_id
                   and s_a.challenge_event_id = s_b.challenge_event_id)
```

**Why it's catastrophically slow**:
1. Cartesian join blows up the data
2. Correlated subquery runs for every row (millions of times)
3. No indexes can help with this pattern
4. This is O(n³) or worse complexity

**Solution**: Use window functions with proper filtering:
```sql
song_played_after_challenge as (
    select
        user_id,
        song_name as first_song,
        challenge_name as first_challenge,
        song_played_at as first_song_played_after_challenge_at
    from (
        select
            sp.user_id,
            sp.song_name,
            co.challenge_name,
            sp.event_happened_at as song_played_at,
            -- Find the most recent challenge BEFORE this song play
            row_number() over (
                partition by sp.user_id, sp.event_id
                order by co.event_happened_at desc
            ) as rn,
            -- Calculate time difference
            date_part('epoch_millisecond', sp.event_happened_at) -
            date_part('epoch_millisecond', co.event_happened_at) as time_diff_ms
        from song_played sp
        inner join challenge_opened co
            on sp.user_id = co.user_id
            -- Only join challenges that happened BEFORE the song play
            and co.event_happened_at < sp.event_happened_at
            -- Only within 2 second window
            and date_part('epoch_millisecond', sp.event_happened_at) -
                date_part('epoch_millisecond', co.event_happened_at) <= 2000
    )
    where rn = 1
    qualify row_number() over (partition by user_id order by song_played_at) = 1
)
```

**Key improvements**:
- Join condition filters BEFORE the Cartesian product
- Window function replaces correlated subquery
- `QUALIFY` clause (if supported) simplifies getting first per user
- Single pass through the data

**Alternative without QUALIFY** (more compatible):
```sql
song_played_after_challenge as (
    with closest_challenge_per_song as (
        select
            sp.user_id,
            sp.event_id as song_event_id,
            sp.song_name,
            sp.event_happened_at as song_played_at,
            co.challenge_name,
            co.event_happened_at as challenge_happened_at,
            row_number() over (
                partition by sp.user_id, sp.event_id
                order by co.event_happened_at desc
            ) as rn
        from song_played sp
        inner join challenge_opened co
            on sp.user_id = co.user_id
            and co.event_happened_at < sp.event_happened_at
            and co.event_happened_at >= dateadd(millisecond, -2000, sp.event_happened_at)
    ),
    first_per_user as (
        select
            user_id,
            song_name,
            challenge_name,
            song_played_at,
            row_number() over (partition by user_id order by song_played_at) as user_rn
        from closest_challenge_per_song
        where rn = 1
    )
    select
        user_id,
        song_name as first_song,
        challenge_name as first_challenge,
        song_played_at as first_song_played_after_challenge_at
    from first_per_user
    where user_rn = 1
)
```

**Performance gain**: Could be **1000-10000x faster**! This is the main bottleneck.

---

## Minor Issues & Suggestions

### 4. Unnecessary SELECT * FROM (Lines 11, 22)

**Current**:
```sql
select * from (
    select user_id, song_name, ...
)
where r_n = 1
```

**Better**: Combine into single SELECT (more readable):
```sql
select
    user_id,
    song_name,
    event_happened_at as first_played_at
from (
    select ..., row_number() over (...) as rn
    from song_played
)
where rn = 1
```

Not a performance issue, just cleaner code.

---

### 5. Ambiguous MIN() in GROUP BY (Lines 57-58)

**Current**:
```sql
min(song_name) as first_song,
min(challenge_name) as first_challenge,
```

**Issue**: Taking `MIN()` of a string is arbitrary - it's alphabetical, not chronological. You probably want the song/challenge associated with the earliest timestamp, not the alphabetically first one.

This is a **logic bug** - you might get the wrong song/challenge name!

**Fix**: This is resolved in the optimized version above where we properly order and select the specific row.

---

## Regarding Incremental Models

You mentioned:
> "I will anyway build some more aggregated tables on top of this one. Maybe I can make those incremental"

**Important**: You **cannot** make downstream tables truly incremental if this dimension table isn't incremental!

**Why**:
- Dimension tables track "lifetime" metrics (first song, last song, total challenges)
- These can change as users continue activity
- If you rebuild this table fully but downstream tables incrementally, they'll have stale data

**Recommendation**:
1. **First**: Optimize this query using the suggestions above
2. **Then**: Consider making THIS table incremental with proper logic:
   - Use `is_incremental()` macro in DBT
   - Update changed users (those with new activity)
   - Merge strategy instead of append

**Example incremental approach**:
```sql
{{
    config(
        materialized='incremental',
        unique_key='user_id',
        on_schema_change='fail'
    )
}}

-- Your optimized query here

{% if is_incremental() %}
    -- Only process users with new activity since last run
    where signed_up_users.user_id in (
        select distinct user_id
        from song_played
        where event_happened_at > (select max(last_played_at) from {{ this }})

        union

        select distinct user_id
        from challenge_opened
        where event_happened_at > (select max(first_song_played_after_challenge_at) from {{ this }})
    )
{% endif %}
```

This way, you only recalculate changed users, and downstream tables can safely be incremental too!

---

## What You Did Well

1. **Clear CTE structure** - Great use of CTEs to break down complex logic
2. **Good naming** - Variable names are descriptive
3. **Business logic understanding** - You correctly identified the need to find challenges before song plays
4. **Left joins in final** - Properly preserving all users even if they lack certain activities

---

## Optimized Full Query

Here's the complete optimized version:

```sql
with
    signed_up_users as (
        select
            user_id,
            country,
            login_at
        from (
            select
                user_id,
                country,
                login_at,
                row_number() over (partition by user_id order by login_at) as rn
            from login
        )
        where rn = 1
    ),

    first_song_played as (
        select
            user_id,
            song_name,
            event_happened_at as first_played_at
        from (
            select
                user_id,
                song_name,
                event_happened_at,
                row_number() over (partition by user_id order by event_happened_at asc) as rn
            from song_played
        )
        where rn = 1
    ),

    last_song_played as (
        select
            user_id,
            song_name,
            event_happened_at as last_played_at
        from (
            select
                user_id,
                song_name,
                event_happened_at,
                row_number() over (partition by user_id order by event_happened_at desc) as rn
            from song_played
        )
        where rn = 1
    ),

    guitar_challenges_discovered as (
        select
            user_id,
            count(distinct event_id) as challenge_times
        from challenge_opened
        where instrument = 'guitar'
        group by user_id
    ),

    song_played_after_challenge as (
        with closest_challenge_per_song as (
            select
                sp.user_id,
                sp.event_id as song_event_id,
                sp.song_name,
                sp.event_happened_at as song_played_at,
                co.challenge_name,
                co.event_happened_at as challenge_happened_at,
                row_number() over (
                    partition by sp.user_id, sp.event_id
                    order by co.event_happened_at desc
                ) as rn
            from song_played sp
            inner join challenge_opened co
                on sp.user_id = co.user_id
                and co.event_happened_at < sp.event_happened_at
                -- Only challenges within 2 seconds before the song play
                and date_part('epoch_millisecond', sp.event_happened_at) -
                    date_part('epoch_millisecond', co.event_happened_at) <= 2000
        ),
        first_per_user as (
            select
                user_id,
                song_name,
                challenge_name,
                song_played_at,
                row_number() over (partition by user_id order by song_played_at) as user_rn
            from closest_challenge_per_song
            where rn = 1  -- Closest challenge for this song
        )
        select
            user_id,
            song_name as first_song,
            challenge_name as first_challenge,
            song_played_at as first_song_played_after_challenge_at
        from first_per_user
        where user_rn = 1  -- First such occurrence per user
    ),

    final as (
        select
            signed_up_users.user_id,
            signed_up_users.country,
            signed_up_users.login_at as first_login,
            first_song_played.song_name as first_song_name,
            first_song_played.first_played_at,
            last_song_played.last_played_at,
            last_song_played.song_name as last_played_song_name,
            guitar_challenges_discovered.challenge_times,
            song_played_after_challenge.first_song as first_challenge_song,
            song_played_after_challenge.first_challenge,
            song_played_after_challenge.first_song_played_after_challenge_at
        from signed_up_users
        left join first_song_played on signed_up_users.user_id = first_song_played.user_id
        left join last_song_played on signed_up_users.user_id = last_song_played.user_id
        left join guitar_challenges_discovered on signed_up_users.user_id = guitar_challenges_discovered.user_id
        left join song_played_after_challenge on signed_up_users.user_id = song_played_after_challenge.user_id
    )

select * from final
```

---

## Expected Performance Improvement

Based on typical data volumes:

| CTE | Original | Optimized | Speedup |
|-----|----------|-----------|---------|
| `signed_up_users` | O(n²) | O(n log n) | **100-1000x** |
| `first_song_played` | O(n log n) | O(n log n) | **2-3x** (less work) |
| `last_song_played` | O(n log n) | O(n log n) | **2-3x** (less work) |
| `song_played_after_challenge` | O(n³) | O(n log n) | **1000-10000x** |

**Overall**: If your query takes 1 hour now, it could run in **1-5 minutes** with these changes!

---

## Next Steps

1. **Test the optimized query** on a sample of data first
2. **Compare results** to ensure logic is preserved (they should match!)
3. **Benchmark performance** - measure before/after execution time
4. **Add indexes** if needed:
   ```sql
   CREATE INDEX idx_song_played_user_time ON song_played(user_id, event_happened_at);
   CREATE INDEX idx_challenge_opened_user_time ON challenge_opened(user_id, event_happened_at);
   CREATE INDEX idx_login_user_time ON login(user_id, login_at);
   ```
5. **Consider incremental materialization** after optimization
6. **Add data quality tests** in DBT (check for nulls, validate logic)

---

## Learning Resources

- **Window Functions**: https://mode.com/sql-tutorial/sql-window-functions/
- **Query Performance**: https://use-the-index-luke.com/
- **DBT Incremental Models**: https://docs.getdbt.com/docs/build/incremental-models

---

## Questions?

Happy to discuss any of these suggestions! The main takeaways:

1. Avoid correlated subqueries in WHERE clauses
2. Use window functions instead
3. Never create Cartesian joins + filter later
4. Filter in JOIN conditions before combining data
5. Window functions are your best friend for this type of analysis

Great work on the business logic - with these performance fixes, this will be a solid, production-ready model!

---

**Estimated review time if this were a real PR**: 45 minutes
**Severity**: High (performance) / Low (correctness)
**Recommendation**: Address performance issues before merging
