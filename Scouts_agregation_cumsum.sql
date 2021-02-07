WITH Payment AS (

WITH couriers AS (

select
d.driver_gk as driver_gk,
d.phone as phone,
(case when d.courier_type is null then 'car' else d.courier_type end ) courier_type,
d.driver_name as driver_name,
d.driver_computed_rating as driver_computed_rating,
f1.fleet_gk as fleet_gk,
d.driver_status as driver_status,
(case when d.frozen_comment = 'Unknown' then '' else d.frozen_comment end ) status,


d.registration_date_key as registration_date_key,
d.ftp_date_key as ftp_date_key_all,
min(f1.order_date_key) as ftp_date_key_park,
min(f1.order_date_key) + interval '30' day FTR_plus_30days,
max(f1.order_date_key) as ltp_date_key,
sum (f1.cost_exc_vat) cost_total

from "emilia_gettdwh"."dwh_dim_drivers_v" d
left join emilia_gettdwh.dwh_fact_drivers_orders_monetization_v f1 on d.driver_gk = f1.driver_gk


where 1=1
and f1.fleet_gk in ( 200017083, 200017177,200017412,200017342,200017205,200017203)
and f1.country_key = 2
and f1.order_status_key = 7
and f1.cost_exc_vat >=1



Group by d.driver_gk,(case when d.courier_type is null then 'car' else d.courier_type end ),d.phone,d.driver_name,d.driver_computed_rating,f1.fleet_gk,d.driver_status,d.registration_date_key,d.ftp_date_key,(case when d.car_number = 'ЧС' then 'ЧС' end),(case when d.frozen_comment = 'Unknown' then '' else d.frozen_comment end ))

(SELECT a.*,
count(distinct(case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) then (case when f2.order_date_key between a.ftp_date_key_park and a.FTR_plus_30days then f2.order_gk end)  end)) as All_rides_30_days,

count(distinct(case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) then f2.order_gk  end)) as All_rides_total,
max (case when a.ftp_date_key_all <> a.ftp_date_key_park then (case when f2.order_date_key  < a.ftp_date_key_park  then f2.order_date_key end) end ) ltp_date_different_park,


count(distinct (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park and a.ftp_date_key_park + interval '6' day then f2.order_gk end)) rides_7_days,
sum (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park and a.ftp_date_key_park + interval '6' day then f2.cost_inc_vat end) cumsum_7_days,
count(distinct (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park + interval '7' day and a.ftp_date_key_park + interval '13' day then f2.order_gk end)) rides_7_to_14_days,
sum (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park + interval '7' day and a.ftp_date_key_park + interval '13' day then f2.cost_inc_vat end) cumsum_7_to_14_days,
count(distinct (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park + interval '14' day and a.ftp_date_key_park + interval '20' day then f2.order_gk end)) rides_15_to_21_days,
sum (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park + interval '14' day and a.ftp_date_key_park + interval '20' day then f2.cost_inc_vat end) cumsum_15_to_21_days,
count(distinct (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park + interval '21' day and a.ftp_date_key_park + interval '29' day then f2.order_gk end)) rides_16_to_30_days,
sum (case when f2.fleet_gk in (200017083, 200017177,200017412,200017342,200017205,200017203) and f2.order_date_key between a.ftp_date_key_park + interval '21' day and a.ftp_date_key_park + interval '29' day then f2.cost_inc_vat end) cumsum_16_to_30_days



from couriers a
left join emilia_gettdwh.dwh_fact_drivers_orders_monetization_v f2 on a.driver_gk = f2.driver_gk

where 1=1

and f2.country_key = 2
and f2.order_status_key = 7
and f2.cost_exc_vat >=1
--and a.FTR_plus_30days >= date '2021-02-01'

GROUP by a.driver_gk,a.cost_total,a.courier_type,a.phone,a.driver_name,a.driver_computed_rating,a.fleet_gk,a.driver_status,a.status,a.registration_date_key,a.ftp_date_key_all,a.ftp_date_key_park,a.FTR_plus_30days,a.ltp_date_key))

(SELECT s.*,
(case when s.ltp_date_different_park >= date '1900-01-01' then (case when date_diff('day', s.ltp_date_different_park,s.ftp_date_key_park) <= 59 then 'NoReFTR' else 'ReFTR' end ) else 'FTR' end) as type_couriers,
(case when f3.date_pay <> '' then date(f3.date_pay) end) as last_pay,
(case when f3.date_pay <> '' then cast (f3.cumsum as integer) else 0 end) as last_CumSum,
(case when  s.ltp_date_different_park >= date '1900-01-01'and date_diff('day', s.ltp_date_different_park,s.ftp_date_key_park) <= 59 and f3.date_pay is null  then 0

    else (case

    when cast (f3.cumsum as integer) = 1800 then (case when s.All_rides_total >= 30 then cast (f3.cumsum as integer) + 1500 else 0 end)
    when cast (f3.cumsum as integer) = 3300 then 0
    when cast (f3.cumsum as integer) = 4000 then 0
    when ftp_date_key_park <= date '2020-12-20' then (case when s.All_rides_total between 5 and 14 then (case when cast (f3.cumsum as integer) >= 0 then 500 - cast (f3.cumsum as integer) else 500 end) else 0 end )
    when ftp_date_key_park <= date '2020-12-20' then (case when s.All_rides_total between 15 and 29 then 1800 else 0 end)
    when ftp_date_key_park <= date '2020-12-20' then (case when s.All_rides_total >= 30 then 3300 else 0 end)
    when s.All_rides_total <= 4 then 0

    when s.All_rides_total between 5 and 14 then (case when cast (f3.cumsum as integer) >= 0 then 500 - cast (f3.cumsum as integer) else 500 end)
    when s.All_rides_total between 15 and 29 then (case when cast (f3.cumsum as integer) >= 0 then 2100 - cast (f3.cumsum as integer) else 2100 end)
    when s.All_rides_total between 15 and 29 then (case when cast (f3.cumsum as integer) >= 0 then 2100 - cast (f3.cumsum as integer) else 2100 end)
    when s.All_rides_total >= 30 then (case when cast (f3.cumsum as integer) >= 0 then 4000 - cast (f3.cumsum as integer) else 4000 end)

    else 0 end ) end) Cumsum

from Payment s
left join sheets.default.Payments_Scouts f3  on cast(f3.id as integer) = cast(substring(cast(s.driver_gk as varchar), 4) as integer)

where 1=1

)