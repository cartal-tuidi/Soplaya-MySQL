drop procedure if exists soplaya.UPDATE_PURCHASE_PROMOTION;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_PURCHASE_PROMOTION()
begin

    /*
    CREO TEMPORANEA CHE METTE INSIEME I RECORD DEGLI SCHEMA DI STAGING:
    soplaya
    soplaya2

     */
    drop temporary table if exists t_soplaya.purchase_promotion_header_full;
    create temporary table t_soplaya.purchase_promotion_header_full
    select promotion_code,
           supplier_code,
           promotion_start_date,
           promotion_end_date,
           description,
           flg_active,
           insert_date,
           update_date,
           to_be_deleted
    from t_soplaya.purchase_promotion
    #     union
#     select promotion_code,
#            supplier_code,
#            promotion_start_date,
#            promotion_end_date,
#            flg_active,
#            description,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_soplaya2.purchase_promotion
    ;


    drop temporary table if exists t_soplaya.purchase_promotion_row_full;
    create temporary table t_soplaya.purchase_promotion_row_full
    select promotion_code,
           product_code,
           promotion_price,
           promotion_type,
           art_code,
           flg_active,
           store_code,
           insert_date,
           update_date,
           to_be_deleted
    from t_soplaya.purchase_promotion
    #     union
#     select promotion_code,
#            product_code,
#            promotion_price,
#            promotion_type,
#            art_code,
#            flg_active,
#            store_code,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_soplaya2.purchase_promotion
    ;


    delete old
    from soplaya.purchase_promotion_header old
             join t_soplaya.purchase_promotion_header_full new on old.promotion_code = new.promotion_code
    where new.to_be_deleted = 1;

/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.purchase_promotion_header (promotion_code,
                                                promotion_start_date,
                                                promotion_end_date,
                                                supplier_registry_id,
                                                description)
-- Inserire tutti i campi della tabella
    select new.promotion_code,
           new.promotion_start_date,
           new.promotion_end_date,
           sr.id,
           new.description
    from t_soplaya.purchase_promotion_header_full new
             inner join soplaya.supplier_registry sr on new.supplier_code = sr.supplier_code
    where new.to_be_deleted = 0
    -- Inserire solo i campi variabili della tabella
    on duplicate key update promotion_start_date = new.promotion_start_date,
                            promotion_end_date   = new.promotion_end_date,
                            supplier_registry_id = sr.id,
                            description          = new.description;


    -- #################################################################################
    -- promotion_row
    -- #################################################################################
    /*
Cancello tutti i record senza una nuova istanza
 */
    delete old
    from soplaya.purchase_promotion_row old
             join soplaya.purchase_promotion_header old2 on old.purchase_promotion_header_id = old2.id
             join soplaya.product p on old.product_id = p.id
             join t_soplaya.purchase_promotion_row_full new
                  on new.promotion_code = old2.promotion_code and p.product_code = new.product_code
    where new.to_be_deleted = 1;


/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.purchase_promotion_row (purchase_promotion_header_id,
                                             product_id,
                                             promotion_price,
                                             promotion_type,
                                             flg_active)

-- Inserire tutti i campi della tabella
    select pplh.id,
           p.id,
           new.promotion_price,
           new.promotion_type,
           new.flg_active
    from t_soplaya.purchase_promotion_row_full new
             inner join soplaya.product p on new.product_code = p.product_code
             inner join soplaya.purchase_promotion_header pplh on new.promotion_code = pplh.promotion_code
    where new.to_be_deleted = 0
    -- Inserire solo i campi variabili della tabella
    on duplicate key update product_id=p.id,
                            promotion_price=new.promotion_price,
                            promotion_type=new.promotion_type,
                            flg_active = new.flg_active;


    -- Aggiorniamo il FLG_ACTIVE sulle righe non aggiornate
    update soplaya.purchase_promotion_row ppr
        inner join soplaya.purchase_promotion_header pph on ppr.purchase_promotion_header_id = pph.id
    set ppr.flg_active = 1
    where current_date between pph.promotion_start_date and pph.promotion_start_date;
    update soplaya.purchase_promotion_row ppr
        inner join soplaya.purchase_promotion_header pph on ppr.purchase_promotion_header_id = pph.id
    set ppr.flg_active = 0
    where current_date not between pph.promotion_start_date and pph.promotion_start_date;

end;




