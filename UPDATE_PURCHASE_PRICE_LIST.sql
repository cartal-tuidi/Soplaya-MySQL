drop procedure if exists crai.UPDATE_PURCHASE_PRICE_LIST;

create
    definer = tuidiadmin@`%` procedure crai.UPDATE_PURCHASE_PRICE_LIST()
begin


    /*
    CREO TEMPORANEA CHE METTE INSIEME I RECORD DEGLI SCHEMA DI STAGING:
    crai
    crai2

     */
    drop temporary table if exists t_craicommon.purchase_price_list_header_full;
    create temporary table t_craicommon.purchase_price_list_header_full
    select purchase_price_list_header_code, supplier_code, description, insert_date, update_date, to_be_deleted
    from t_crai.purchase_price_list
    #     union
#     select purchase_price_list_header_code, supplier_code, description, insert_date, update_date, to_be_deleted
#     from t_crai2.purchase_price_list
    ;


    drop temporary table if exists t_craicommon.purchase_price_list_row_full;
    create temporary table t_craicommon.purchase_price_list_row_full
    select purchase_price_list_row_code,
           price,
           purchase_price_list_header_code,
           start_date,
           end_date,
           art_code,
           flg_active,
           store_code,
           product_code,
           out_of_stock,
           description,
           insert_date,
           update_date,
           to_be_deleted
    from t_crai.purchase_price_list
    #     union
#     select purchase_price_list_row_code,
#            price,
#            purchase_price_list_header_code,
#            start_date,
#            end_date,
#            art_code,
#            flg_active,
#            store_code,
#            product_code,
#            out_of_stock,
#            description,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_crai2.purchase_price_list
    ;

    -- #################################################################################
    -- purchase_price_list_header
    -- #################################################################################
/*
Cancello tutti i record senza una nuova istanza
 */
#     delete
#     from crai.purchase_price_list_header old
#     where old.purchase_price_list_header_code not in
#           (select new.purchase_price_list_header_code
#            from t_craicommon.purchase_price_list_header_full new);

/*
Inserisco le nuove istanze dei record esistenti
 */

    insert into crai.purchase_price_list_header (purchase_price_list_header_code,
                                                 supplier_registry_id,
                                                 description)
-- Inserire tutti i campi della tabella
    select new.purchase_price_list_header_code,
           sr.id,
           new.description
    from t_craicommon.purchase_price_list_header_full new
             inner join crai.supplier_registry sr on new.supplier_code = sr.supplier_code
    -- Inserire solo i campi variabili della tabella
    on duplicate key update supplier_registry_id = sr.id,
                            description          = new.description;


    -- #################################################################################
    -- purchase_price_list_row
    -- #################################################################################
    /*
Cancello tutti i record senza una nuova istanza
 */
    delete old
    from crai.purchase_price_list_row old
             join t_craicommon.purchase_price_list_row_full new
                  on new.purchase_price_list_row_code = old.purchase_price_list_row_code
    where new.to_be_deleted = 1;

/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into crai.purchase_price_list_row (purchase_price_list_row_code,
                                              purchase_price_list_header_id,
                                              product_id,
                                              price,
                                              start_date,
                                              end_date,
                                              out_of_stock,
                                              flg_active)

    select new.purchase_price_list_row_code,
           pplh.id,
           p.id,
           new.price,
           new.start_date,
           new.end_date,
           new.out_of_stock,
           new.flg_active
    from t_craicommon.purchase_price_list_row_full new
             INNER JOIN crai.product p
                        on new.product_code = p.product_code
             inner join crai.purchase_price_list_header pplh
                        on new.purchase_price_list_header_code = pplh.purchase_price_list_header_code
             join crai.art_registry on p.art_registry_id = art_registry.id
             join crai.store_registry on p.store_registry_id = store_registry.id
             join crai.supplier_registry s on pplh.supplier_registry_id = s.id
    -- NON PIù NECESSARIO (cancellare il campo)
    -- join crai.art_supplier_registry asr
    --      on art_registry.id = asr.art_registry_id and s.id = asr.supplier_registry_id
    -- Inserire solo i campi variabili della tabella
    where new.to_be_deleted = 0
    on duplicate key update purchase_price_list_header_id=pplh.id,
                            product_id=p.id,
                            price=new.price,
                            start_date=new.start_date,
                            end_date=new.end_date,
                            out_of_stock=new.out_of_stock,
                            flg_active  = new.flg_active;

    -- Aggiorniamo il FLG_ACTIVE sulle righe non aggiornate
    update crai.purchase_price_list_row pplr
    set pplr.flg_active = 1
    where current_date between pplr.start_date and pplr.end_date;
    update crai.purchase_price_list_row pplr
    set pplr.flg_active = 0
    where current_date not between pplr.start_date and pplr.end_date;

END;

