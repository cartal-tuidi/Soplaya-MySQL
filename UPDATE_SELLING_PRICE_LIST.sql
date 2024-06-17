drop procedure if exists soplaya.UPDATE_SELLING_PRICE_LIST;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_SELLING_PRICE_LIST()
begin

    insert into soplaya.selling_price_list_header (selling_price_list_header_code, description)
-- Inserire tutti i campi della tabella
    select distinct  new.selling_price_list_header_code, new.description
    from t_soplaya.selling_price_list new
    -- Inserire solo i campi variabili della tabella
    on duplicate key update description=new.description;


    -- #################################################################################
    -- selling_price_list_row
    -- #################################################################################
    /*
Cancello tutti i record senza una nuova istanza
 */

    delete old
    from soplaya.selling_price_list_row old
             join t_soplaya.selling_price_list new
                  on old.selling_price_list_row_code = new.selling_price_list_row_code
    where new.to_be_deleted = 1;

/*
Inserisco le nuove istanze dei record esistenti
 */


    insert into soplaya.selling_price_list_row (selling_price_list_row_code,
                                                selling_price_list_header_id,
                                                product_id,
                                                price,
                                                start_date,
                                                end_date, out_of_stock, description,
                                                flg_active)
-- Inserire tutti i campi della tabella
    select new.selling_price_list_row_code,
           new.selling_price_list_header_id,
           new.product_id,
           new.price,
           new.start_date,
           new.end_date,
           new.out_of_stock,
           new.description,
           new.flg_active
    from (select splh.id selling_price_list_header_id,
                 p.id    product_id,
                 splr.price,
                 splr.start_date,
                 splr.end_date,
                 splr.out_of_stock,
                 splr.description,
                 splr.selling_price_list_row_code,
                 splr.flg_active
          from t_soplaya.selling_price_list splr
                   INNER JOIN soplaya.product p
                              on splr.product_code = p.product_code
                   inner join soplaya.selling_price_list_header splh
                              on splh.selling_price_list_header_code = splr.selling_price_list_header_code
          where splr.to_be_deleted = 0) new

    -- Inserire solo i campi variabili della tabella
    on duplicate key update selling_price_list_header_id = new.selling_price_list_header_id,
                            product_id                   = new.product_id,
                            price                        = new.price,
                            start_date                   = new.start_date,
                            end_date                     = new.end_date,
                            out_of_stock                 = new.out_of_stock,
                            description                  = new.description,
                            flg_active                   = new.flg_active;

        -- Aggiorniamo il FLG_ACTIVE sulle righe non aggiornate
    update soplaya.selling_price_list_row splr
    set splr.flg_active = 1
    where current_date between splr.start_date and splr.end_date;
    update soplaya.selling_price_list_row splr
    set splr.flg_active = 0
    where current_date not between splr.start_date and splr.end_date;

END;





