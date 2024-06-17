drop procedure if exists soplaya.UPDATE_STOCK;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_STOCK()
begin

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
    from t_soplaya.stock new
             inner join soplaya.product p on p.product_code = new.product_code
    ON DUPLICATE KEY UPDATE stock      = new.stock,
                            start_date = current_date,
                            end_date   = '2999-12-31',
                            flg_active = 1;

END;


