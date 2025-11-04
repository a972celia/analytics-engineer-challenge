with 
    signed_up_users as (
        select
            user_id,
            country,
            login_at
        from login as lla
             where login_at = (select min(login_at) from login llb where lla.user_id = llb.user_id)
    ),
     first_song_played as (
         select * from (
            select 
                user_id,
                song_name,
                min(event_happened_at) over (partition by user_id order by event_happened_at asc) as first_played_at,
                row_number() over (partition by user_id order by event_happened_at asc) as r_n
            from song_played
        )
        where r_n = 1
    ),
     last_song_played as (
        select * from (
            select
                user_id,
                song_name,
                max(event_happened_at) over (partition by user_id order by event_happened_at desc) as last_played_at,
                row_number() over (partition by user_id order by event_happened_at desc) as r_n
            from song_played
        )
        where r_n = 1
    ),
     guitar_challenges_discovered as (
        select
            user_id,
            count(distinct event_id) as challenge_times
        from challenge_opened
          where instrument = 'guitar'
        group by user_id
    ),
     song_played_after_challenge_staging as (
        select
            song_played.user_id,
            song_played.song_name,
            song_played.event_id           as song_event_id,
            challenge_opened.challenge_name,
            challenge_opened.event_id      as challenge_event_id,
            song_played.event_happened_at  as song_played_at,
            date_part(epoch_millisecond,
                              song_played.event_happened_at) -  date_part(epoch_millisecond,
                                                              challenge_opened.event_happened_at) as time_diff
        from song_played
            left join challenge_opened on song_played.user_id = challenge_opened.user_id
     ),
     song_played_after_challenge as (
        select
            s_a.user_id,
            min(song_name)      as first_song,
            min(challenge_name) as first_challenge,
            min(song_played_at) as first_song_played_after_challenge_at
        from song_played_after_challenge_staging s_a
             where time_diff <= 2000 and time_diff > 0
                   and time_diff = (select min(time_diff)
                                           from song_played_after_challenge_staging s_b
                                                where s_a.user_id = s_b.user_id
                                                      and s_a.song_event_id = s_b.song_event_id
                                                      and s_a.challenge_event_id = s_b.challenge_event_id
                                                      )
        group by user_id
     ),

     final as (
        select
            signed_up_users.user_id,
            signed_up_users.country,
            signed_up_users.login_at    as first_login,
            first_song_played.song_name as first_song_name,
            first_song_played.first_played_at,
            last_song_played.last_played_at,
            last_song_played.song_name  as last_played_song_name,
            guitar_challenges_discovered.challenge_times,
            song_played_after_challenge.first_song as first_challenge_song,
            song_played_after_challenge.first_challenge,
            song_played_after_challenge.first_song_played_after_challenge_at
        from signed_up_users
          left join first_song_played on signed_up_users.user_id = first_song_played.user_id
          left join last_song_played on signed_up_users.user_id = last_song_played.user_id
          left join guitar_challenges_discovered on signed_up_users.user_id = guitar_challenges_discovered.user_id
          left join song_played_after_challenge
                           on signed_up_users.user_id = song_played_after_challenge.user_id
    )

select * from final
