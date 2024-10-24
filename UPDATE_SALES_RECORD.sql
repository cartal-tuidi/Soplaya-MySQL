drop procedure if exists soplaya.UPDATE_SALES_RECORD;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_SALES_RECORD()
begin

    /*
    CREO TEMPORANEA CHE METTE INSIEME I RECORD DEGLI SCHEMA DI STAGING:
    soplaya
    soplaya2

     */
    drop temporary table if exists t_soplaya.sales_record_full;
    create temporary table t_soplaya.sales_record_full
    select product_code,
           quantity_sold,
           amount,
           reg_date,
           reg_last_time,
           art_code,
           store_code,
           discount,
           flg_promo,
           insert_date,
           update_date,
           to_be_deleted
    from t_soplaya.sales_record_aggr
    #     union
#     select product_code,
#            quantity_sold,
#            amount,
#            reg_date,
#            reg_last_time,
#            art_code,
#            store_code,
#            discount,
#            flg_promo,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_soplaya2.sales_record
    ;

    -- #########################################################################################
/*
Cancello tutti i record senza una nuova istanza negli ultimi 7 giorni
 */
    /*
    delete old
    from soplaya.sales_record old
        join soplaya.product p on old.product_id = p.id
    join t_soplaya.sales_record_full new on new.product_code=p.product_code and old.reg_date=new.reg_date;


    -- #########################################################################################
/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.sales_record (product_id, quantity_sold, amount, reg_date, reg_last_time, discount, flg_promo)
-- Inserire tutti i campi della tabella
    select p.id,
           new.quantity_sold,
           new.amount,
           new.reg_date,
           new.reg_last_time,
           new.discount,
           new.flg_promo
    from t_soplaya.sales_record_aggr
        new
             inner join soplaya.product p
                        on p.product_code = new.product_code
    -- Inserire solo i campi variabili della tabella
    on duplicate key update quantity_sold=new.quantity_sold,
                            amount=new.amount,
                            reg_last_time=new.reg_last_time,
                            discount=new.discount,
                            flg_promo = new.flg_promo;

    -- ##################################################################
-- Aggiornamento SALES_RECORD_FILTERED
-- ##################################################################

    delete
    from soplaya.sales_record_filtered
    where reg_date < date_add(now(), interval -4 month);

    insert into soplaya.sales_record_filtered (amount, discount, product_id, reg_date, reg_last_time, quantity_sold,
                                            flg_promo,
                                            insert_date, update_date)
    select amount,
           discount,
           product_id,
           reg_date,
           reg_last_time,
           quantity_sold,
           flg_promo,
           insert_date,
           update_date
    from soplaya.sales_record sr
    where reg_date >= date_add(now(), interval -2 month)
    on duplicate key update amount        = sr.amount,
                            discount      = sr.discount,
                            reg_last_time = sr.reg_last_time,
                            quantity_sold = sr.quantity_sold,
                            flg_promo     = sr.flg_promo;


END;

