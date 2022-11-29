-- make scheduled inserts (jobs in schema cron) for deal stage dash daily
SELECT cron.schedule('insert_upcoming_deals_daily', -- name
                     '30 9 * * *', --time
                    'INSERT INTO sc.upcoming_deals_by_time
                        SELECT
                        SUM("Deals"."Betrag 1"::numeric + "Deals"."Betrag 2"::numeric) betrag,
				        NOW()::timestamp as date_time
			            FROM zoho."Deals" 
			            WHERE "Deals"."Probability (%)" >= 50
			                AND "Deals"."Probability (%)" <= 85
                    ON CONFLICT (date_time)
                    DO NOTHING;'
                    );

