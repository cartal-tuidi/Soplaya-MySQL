drop procedure if exists crai.UPDATE_SELLING_PRICE_LIST;

create
    definer = tuidiadmin@`%` procedure crai.UPDATE_SELLING_PRICE_LIST()
begin

    /*
    CREO TEMPORANEA CHE METTE INSIEME I RECORD DEGLI SCHEMA DI STAGING:
    crai
    crai2

     */
    drop temporary table if exists t_craicommon.selling_price_list_header_full;
    create temporary table t_craicommon.selling_price_list_header_full
    select selling_price_list_header_code, description, insert_date, update_date, to_be_deleted
    from t_crai.selling_price_list
#     union
#     select selling_price_list_header_code, description, insert_date, update_date, to_be_deleted
#     from t_crai2.selling_price_list_header
    ;


    drop temporary table if exists t_craicommon.selling_price_list_row_full;
    create temporary table t_craicommon.selling_price_list_row_full
    select selling_price_list_row_code,
           selling_price_list_header_code,
           price,
           start_date,
           end_date,
           art_code,
           store_code,
           product_code,
           out_of_stock,
           description,
           original_end_date,
           flg_active,
           insert_date,
           update_date,
           to_be_deleted
    from t_crai.selling_price_list
#     union
#     select selling_price_list_row_code,
#            selling_price_list_header_code,
#            price,
#            start_date,
#            end_date,
#            art_code,
#            store_code,
#            product_code,
#            out_of_stock,
#            description,
#            original_end_date,
#            flg_active,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_crai2.selling_price_list
    ;


    insert into crai.selling_price_list_header (selling_price_list_header_code, description)
-- Inserire tutti i campi della tabella
    select new.selling_price_list_header_code, new.description
    from t_craicommon.selling_price_list_header_full new
    -- Inserire solo i campi variabili della tabella
    on duplicate key update description=new.description;


    -- #################################################################################
    -- selling_price_list_row
    -- #################################################################################
    /*
Cancello tutti i record senza una nuova istanza
 */

    delete old
    from crai.selling_price_list_row old
             join t_craicommon.selling_price_list_row_full new
                  on old.selling_price_list_row_code = new.selling_price_list_row_code
    where new.to_be_deleted = 1;

/*
Inserisco le nuove istanze dei record esistenti
 */


    insert into crai.selling_price_list_row (selling_price_list_row_code,
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
          from t_craicommon.selling_price_list_row_full splr
                   INNER JOIN crai.product p
                              on splr.product_code = p.product_code
                   inner join crai.selling_price_list_header splh
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
    update crai.selling_price_list_row splr
    set splr.flg_active = 1
    where current_date between splr.start_date and splr.end_date;
    update crai.selling_price_list_row splr
    set splr.flg_active = 0
    where current_date not between splr.start_date and splr.end_date;

END;





