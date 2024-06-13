drop procedure if exists soplaya.UPDATE_ART_SUPPLIER_REGISTRY;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_ART_SUPPLIER_REGISTRY()
begin


    /*
    Cancello tutti i record flaggati come da cancellare nel caricamento di oggi
     */
    delete old
    from soplaya.art_supplier_registry old
             inner join t_soplaya.art_supplier_registry new
                        on new.art_supplier_code = old.art_supplier_code
    where new.to_be_deleted = 1;

    -- #########################################################################################

/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.art_supplier_registry (art_registry_id,
                                            supplier_registry_id,
                                            art_supplier_code,
                                            external_art_code,
                                            pack_pallet,
                                            pack_layer,
                                            pack_qty,
                                            flg_active)
-- Inserire tutti i campi della tabella
    select distinct art.id                as art_registry_id
                  , sr.id                 as supplier_registry_id
                  , asr.art_supplier_code as art_supplier_code
                  , asr.external_art_code as external_art_code
                  , asr.pack_pallet       as pack_pallet
                  , asr.pack_layer        as pack_layer
                  , asr.pack_qty          as pack_qty
                  , pplr.flg_active       as flg_active
    from t_soplaya.art_supplier_registry asr
             inner join soplaya.art_registry art
                        on art.art_code = asr.art_code
             inner join soplaya.product p
                        on art.id = p.art_registry_id
             inner join soplaya.purchase_price_list_row pplr
                        on p.id = pplr.product_id
             inner join soplaya.purchase_price_list_header pplh
                        on pplr.purchase_price_list_header_id = pplh.id
             inner join soplaya.supplier_registry sr
                        on sr.supplier_code = asr.supplier_code
                            and sr.id = pplh.supplier_registry_id
    where current_date between pplr.start_date and pplr.end_date
    on duplicate key update
                         -- Inserire solo i campi variabili della tabella
                         art_registry_id      = art.id,
                         supplier_registry_id = sr.id,
                         pack_pallet          = asr.pack_pallet,
                         pack_layer           = asr.pack_layer,
                         pack_qty             = asr.pack_qty,
                         flg_active           = pplr.flg_active;

END;