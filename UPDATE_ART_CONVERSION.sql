drop procedure if exists soplaya.UPDATE_ART_CONVERSION;


create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_ART_CONVERSION()
begin

    /*
    Cancello tutti i record senza una nuova istanza
     */
    with t_soplaya_art_conversion as (select ac.*, ar1.id lv1_id, ar2.id lv2_id
                                    from t_soplaya.art_conversion ac
                                             inner join soplaya.art_registry ar1 on ar1.art_code = ac.Art_code_lv1
                                             inner join soplaya.art_registry ar2 on ar2.art_code = ac.Art_code_lv2)
    delete old
    from soplaya.art_conversion old
             inner join t_soplaya_art_conversion new
                       on new.lv1_id = old.art_id_lv_1
                           and new.lv2_id = old.art_id_lv_2
    where to_be_deleted = 1;

    -- #########################################################################################
/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.art_conversion (art_id_lv_1,
                                        art_id_lv_2,
                                        Ratio, type)
-- Inserire tutti i campi della tabella
    select ar1.id,
           ar2.id,
           new.Ratio,
           new.type
    from t_soplaya.art_conversion new
             inner join soplaya.art_registry ar1 on ar1.art_code = new.Art_code_lv1
             inner join soplaya.art_registry ar2 on ar2.art_code = new.Art_code_lv2
    where to_be_deleted = 0
    on duplicate key update
                         -- Inserire solo i campi variabili della tabella
                         Ratio = new.Ratio,
                         type  = new.type;

END;

