drop procedure if exists soplaya.UPDATE_PRODUCT;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_PRODUCT()
begin

    /*
    CREO TEMPORANEA CHE METTE INSIEME I RECORD DEGLI SCHEMA DI STAGING:
    soplaya
    soplaya2

     */
    drop temporary table if exists t_soplaya.product_full;
    create temporary table t_soplaya.product_full
    select product_code,
           art_code,
           store_code,
           shelf_qty,
           flg_in_stock,
           to_be_deleted,
           insert_date,
           update_date,
           flg_active
    from t_soplaya.product
#     union
#     select product_code,
#            art_code,
#            store_code,
#            shelf_qty,
#            flg_in_stock,
#            to_be_deleted,
#            insert_date,
#            update_date,
#            clusterass,
#            raggr_scelto,
#            classe,
#            classe_default,
#            flg_active
#     from t_soplaya2.product
    ;
    -- #########################################################################################
/*
Disattiviamo tutti i record senza una nuova istanza
*/
-- Non cancelliamo gli articolo:
-- 1) li disattiviamo con FLG_ACTIVE = 0
-- 2) aggiorniamo il FLG_IN_STOCK = 0 per segnarli come fuori assortimento
-- 3) cancello la ACTIVATION_DATE per poter tracciare l'eventuale riattivazione futura
    UPDATE soplaya.product old
        JOIN t_soplaya.product_full new
        ON old.product_code = new.product_code
    SET old.flg_active      = 0,
        old.flg_in_stock    = 0,
        old.activation_date = null
    WHERE new.to_be_deleted = 1;

    -- #########################################################################################
/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.product ( product_code
                                , art_registry_id
                                , store_registry_id
                                , shelf_qty
                                , flg_in_stock
                                , flg_active)
-- Inserire tutti i campi della tabella
    select new.product_code
         , ar.id
         , sr.id
         , new.shelf_qty
         , new.flg_in_stock
         , new.flg_active
    from t_soplaya.product_full new
             inner join art_registry ar on new.art_code = ar.art_code
             inner join store_registry sr on new.store_code = sr.store_code
    -- Inserire solo i campi variabili della tabella
    on duplicate key update art_registry_id=ar.id
                          , store_registry_id=sr.id
                          , shelf_qty =     new.shelf_qty
                          , flg_in_stock =  new.flg_in_stock
                          , flg_active =    new.flg_active;


END;

