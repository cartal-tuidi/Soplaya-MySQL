drop procedure if exists soplaya.UPDATE_PRODUCT_SUPPLIER_REGISTRY;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_PRODUCT_SUPPLIER_REGISTRY()
begin


    /*
    disattivo tutti i record flaggati come da cancellare nel caricamento di oggi
     */
    update soplaya.product_supplier_registry old
             inner join t_soplaya.product_supplier_registry new
                        on new.product_supplier_code = old.product_supplier_code
    set old.flg_active = 0
    where new.to_be_deleted = 1;

    -- #########################################################################################

/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.product_supplier_registry(flg_active,
                                                  product_id,
                                                  supplier_registry_id,
                                                  product_supplier_code,
                                                  external_art_code,
                                                  weight,
                                                  pack_layer,
                                                  pack_pallet,
                                                  pack_qty)
-- Inserire tutti i campi della tabella
    select distinct psr.flg_active as flg_active
                  , p.id           as product_id
                  , sr.id
                  , psr.product_supplier_code
                  , psr.external_art_code
                  , psr.weight
                  , psr.pack_layer
                  , psr.pack_pallet
                  , psr.pack_qty
    from t_soplaya.product_supplier_registry psr
             inner join soplaya.product p
                        on psr.product_code = p.product_code
             inner join soplaya.purchase_price_list_row pplr
                        on p.id = pplr.product_id
             inner join soplaya.purchase_price_list_header pplh
                        on pplr.purchase_price_list_header_id = pplh.id
             inner join soplaya.supplier_registry sr
                        on sr.supplier_code = psr.supplier_code
                            and sr.id = pplh.supplier_registry_id
    where current_date between pplr.start_date and pplr.end_date
    on duplicate key update external_art_code = psr.external_art_code
                          , weight            = psr.weight
                          , pack_layer        = psr.pack_layer
                          , pack_pallet       = psr.pack_pallet
                          , pack_qty          = psr.pack_qty
                          , flg_active        = psr.flg_active;
    -- Inserire solo i campi variabili della tabella

END;