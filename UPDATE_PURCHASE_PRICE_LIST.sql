drop procedure if exists soplaya.UPDATE_PURCHASE_PRICE_LIST;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_PURCHASE_PRICE_LIST()
begin


    insert into soplaya.purchase_price_list_header (purchase_price_list_header_code,
                                                 supplier_registry_id,
                                                 description)
-- Inserire tutti i campi della tabella
    select new.purchase_price_list_header_code,
           sr.id,
           new.description
    from t_soplaya.purchase_price_list new
             inner join soplaya.supplier_registry sr on new.supplier_code = sr.supplier_code
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
    from soplaya.purchase_price_list_row old
             join t_soplaya.purchase_price_list new
                  on new.purchase_price_list_row_code = old.purchase_price_list_row_code
    where new.to_be_deleted = 1;

/*
Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.purchase_price_list_row (purchase_price_list_row_code,
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
    from t_soplaya.purchase_price_list new
             INNER JOIN soplaya.product p
                        on new.product_code = p.product_code
             inner join soplaya.purchase_price_list_header pplh
                        on new.purchase_price_list_header_code = pplh.purchase_price_list_header_code
             join soplaya.art_registry on p.art_registry_id = art_registry.id
             join soplaya.store_registry on p.store_registry_id = store_registry.id
             join soplaya.supplier_registry s on pplh.supplier_registry_id = s.id
    -- NON PIù NECESSARIO (cancellare il campo)
    -- join soplaya.art_supplier_registry asr
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
    update soplaya.purchase_price_list_row pplr
    set pplr.flg_active = 1
    where current_date between pplr.start_date and pplr.end_date;
    update soplaya.purchase_price_list_row pplr
    set pplr.flg_active = 0
    where current_date not between pplr.start_date and pplr.end_date;

END;

