drop procedure if exists soplaya.UPDATE_SELLING_PROMOTION;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_SELLING_PROMOTION()
begin

    /*
    CREO TEMPORANEA CHE METTE INSIEME I RECORD DEGLI SCHEMA DI STAGING:
    soplaya
    soplaya2

     */
    drop temporary table if exists t_soplaya.selling_promotion_header_full;
    create temporary table t_soplaya.selling_promotion_header_full
    select promotion_code,
           min_promotion_start_date,
           max_promotion_end_date,
           promotion_end_date,
           description,
           flg_active,
           insert_date,
           update_date,
           to_be_deleted
    from t_soplaya.selling_promotion
    #     union
#     select promotion_code,
#            min_promotion_start_date,
#            max_promotion_end_date,
#            description,
#            flg_active,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_soplaya2.selling_promotion
    ;


    drop temporary table if exists t_soplaya.selling_promotion_row_full;
    create temporary table t_soplaya.selling_promotion_row_full
    select promotion_code,
           product_code,
           promotion_price,
           promotion_type,
           art_code,
           store_code,
           flg_active,
           promo_channel_code,
           flg_first_promo,
           promotion_start_date,
           promotion_end_date,
           min_promotion_start_date,
           max_promotion_end_date,
           insert_date,
           update_date,
           to_be_deleted
    from t_soplaya.selling_promotion
    #     union
#     select promotion_code,
#            product_code,
#            promotion_price,
#            promotion_type,
#            art_code,
#            flg_active,
#            store_code,
#            promo_channel_code,
#            flg_first_promo,
#            min_promotion_start_date,
#            max_promotion_end_date,
#            insert_date,
#            update_date,
#            to_be_deleted
#     from t_soplaya2.selling_promotion
    ;


    -- #################################################################################
    -- promotion_header
    -- #################################################################################
/*
Cancello tutti i record senza una nuova istanza

 */

#     delete old
#     from soplaya.selling_promotion_header old
#              join t_soplaya.selling_promotion_header_full new on new.promotion_code = old.promotion_code
#     where new.to_be_deleted = 1;

/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.selling_promotion_header (promotion_code, promotion_start_date, promotion_end_date, description)
-- Inserire tutti i campi della tabella
    select distinct new.promotion_code,
                    new.min_promotion_start_date,
                    new.max_promotion_end_date,
                    new.description
    from t_soplaya.selling_promotion_header_full new
    where to_be_deleted = 0
    -- Inserire solo i campi variabili della tabella
    on duplicate key update promotion_start_date = new.min_promotion_start_date,
                            promotion_end_date   = new.max_promotion_end_date,
                            description          = new.description;


    -- #################################################################################
    -- promotion_row
    -- #################################################################################
    /*
Cancello tutti i record senza una nuova istanza
 */
    delete old
    from soplaya.selling_promotion_row old
             -- cancello solo i record dei listini non trovati durante il caricamento degli ultimi 7 giorni
             inner join soplaya.selling_promotion_header h
                        on h.id = old.selling_promotion_header_id
             inner join soplaya.product p on p.id = old.product_id
             inner join t_soplaya.selling_promotion_row_full new
                        on new.promotion_code = h.promotion_code and new.product_code = p.product_code
    where new.to_be_deleted = 1;


/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.selling_promotion_row (selling_promotion_header_id,
                                            product_id,
                                            promotion_price,
                                            promotion_type,
                                            promotion_start_date,
                                            promotion_end_date,
                                            promo_channel_id,
                                            flg_first_promo,
                                            flg_active)
-- Inserire tutti i campi della tabella
    select distinct splh.id,
                    p.id,
                    new.promotion_price,
                    new.promotion_type,
                    new.promotion_start_date,
                    new.promotion_end_date,
                    new.promo_channel_code as promo_channel_id,
                    new.flg_first_promo,
                    new.flg_active
    from t_soplaya.selling_promotion_row_full new
             inner join soplaya.selling_promotion_header splh
                        on splh.promotion_code = new.promotion_code
             inner join soplaya.product p on p.product_code = new.product_code
    where new.to_be_deleted = 0
    -- Inserire solo i campi variabili della tabella
    on duplicate key update product_id           = p.id,
                            promotion_price      = new.promotion_price,
                            promotion_type       = new.promotion_type,
                            promo_channel_id     = new.promo_channel_code,
                            flg_first_promo      = new.flg_first_promo,
                            promotion_start_date = new.promotion_start_date,
                            promotion_end_date   = new.promotion_end_date,
                            flg_active           = new.flg_active;


    -- Aggiorniamo il FLG_ACTIVE sulle righe non aggiornate
    update soplaya.selling_promotion_row spr
    set spr.flg_active = 1
    where current_date between spr.promotion_start_date and spr.promotion_end_date;
    update soplaya.selling_promotion_row spr
    set spr.flg_active = 0
    where current_date not between spr.promotion_start_date and spr.promotion_end_date;

END;

