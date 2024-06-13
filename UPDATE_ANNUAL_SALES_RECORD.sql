drop procedure if exists soplaya.UPDATE_ANNUAL_SALES_RECORD;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_ANNUAL_SALES_RECORD()
begin

    set @range_days = 30;
    set @total_days = 360;

    drop temporary table if exists soplaya.t_annual_sales_record;

    create temporary table soplaya.t_annual_sales_record
    with asr_full as
             (select p.product_code                                        as product_code,
                     COUNT(distinct sr.reg_date)                           as range_sold_day,
                     SUM(sr.amount)                                        as range_amount,
                     SUM(sr.discount)                                      as range_discount,
                     SUM(sr.quantity_sold)                                 as range_quantity_sold,
                     floor(datediff(sysdate(), sr.reg_date) / @range_days) as range_part
              from soplaya.sales_record sr
                       inner join soplaya.product p on sr.product_id = p.id
              where sr.reg_date > SUBDATE(sysdate(), interval @total_days DAY)
              group by p.product_code, floor(datediff(sysdate(), sr.reg_date) / @range_days))
    select af.product_code,
           sum(af.range_sold_day)      as sold_day,
           SUM(af.range_amount)        as annual_amount,
           SUM(af.range_discount)      as annual_discount,
           sum(af.range_quantity_sold) as annual_quantity_sold,
           AVG(af.range_quantity_sold) as avg_annual_quantity_sold
    from asr_full as af
    group by af.product_code;

    -- #########################################################################################
/*
Cancello tutti i record senza una nuova istanza
 */
    DELETE old
    FROM soplaya.annual_sales_record old
             inner join soplaya.product p on old.product_id = p.id
    WHERE p.product_code not in (SELECT DISTINCT new.product_code
                                 FROM soplaya.t_annual_sales_record new);


    -- #########################################################################################
/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.annual_sales_record (product_id,
                                             sold_day,
                                             annual_amount,
                                             annual_discount,
                                             annual_quantity_sold,
                                             avg_annual_quantity_sold)
-- Inserire tutti i campi della tabella
    select p2.id,
           new.sold_day,
           new.annual_amount,
           new.annual_discount,
           new.annual_quantity_sold,
           new.avg_annual_quantity_sold
    from soplaya.t_annual_sales_record new
             inner join soplaya.product p2 on new.product_code = p2.product_code
    -- Inserire solo i campi variabili della tabella
    on duplicate key update sold_day                 = new.sold_day,
                            annual_amount            = new.annual_amount,
                            annual_discount          = new.annual_discount,
                            annual_quantity_sold     = new.annual_quantity_sold,
                            avg_annual_quantity_sold = new.avg_annual_quantity_sold;


END;

