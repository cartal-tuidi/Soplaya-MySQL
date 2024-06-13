drop procedure if exists soplaya.UPDATE_STOCK;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_STOCK()
begin

    /*
CREO TEMPORANEA CHE METTE INSIEME I RECORD DEGLI SCHEMA DI STAGING:
soplaya
soplaya2

 */
    drop temporary table if exists t_soplaya.stock_full;
    create temporary table t_soplaya.stock_full
    select stock,
           product_code,
           warehouse_lot,
           start_date,
           end_date,
           flg_active,
           insert_date,
           update_date,
           to_be_deleted
    from t_soplaya.stock
    #     union
#     select stock,
#            product_code,
#            warehouse_lot,
#            start_date,
#            end_date,
#            flg_active,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_soplaya2.stock
    ;


    -- #################################################################################
    -- CANCELLAZIONI
    -- #################################################################################

    -- cancello tutti i record che non trovo nel caricamento di oggi -> non hanno giacenza aggiornata/attiva

    delete old
    from soplaya.stock old
             inner join (select p.id as product_id ,s.to_be_deleted, s.flg_active
                         from t_soplaya.stock s
                                  inner join soplaya.product p
                                             on p.product_code = s.product_code) new
                        on new.product_id = old.product_id
    where new.to_be_deleted = 1 or new.flg_active = 0;

#     delete old
#     from soplaya.stock old
#     where product_id not in (select distinct p.id
#                              from t_soplaya.stock s
#                                       inner join product p on p.product_code = s.product_code
#                              where s.flg_active = 1
#                                and s.to_be_deleted = 0);

    -- #################################################################################
    -- INSERIMENTI / AGGIORNAMENTI
    -- #################################################################################

/*
Inserisco le nuove istanze dei record esistenti, in caso di aggiornamento all'interno della stessa giornata, aggiorno il valore della giacenza
 */
    insert into soplaya.stock(stock, product_id, warehouse_lot, start_date, end_date, flg_active)
-- Inserire tutti i campi della tabella
    select new.stock,
           p.id,
           new.warehouse_lot,
           current_date as start_date,
           '2999-12-31' as end_date,
           1            as flg_active
    from t_soplaya.stock_full new
             inner join soplaya.product p on p.product_code = new.product_code
    ON DUPLICATE KEY UPDATE stock      = new.stock,
                            start_date = current_date,
                            end_date   = '2999-12-31',
                            flg_active = 1;

END;


