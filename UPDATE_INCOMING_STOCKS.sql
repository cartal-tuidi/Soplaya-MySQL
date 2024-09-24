drop procedure if exists soplaya.UPDATE_INCOMING_STOCKS;
create procedure soplaya.UPDATE_INCOMING_STOCKS()
begin

    insert into soplaya.incoming_stock(product_id, delivery_date, packs, pieces, pallets, layers)
    -- Inserire tutti i campi della tabella
    select new.product_id,
           new.delivery_date,
           new.packs,
           new.pieces,
           new.pallets,
           new.layers


    from (select p.id              as product_id
               , i_s.delivery_date as delivery_date
               , i_S.packs         as packs
               , i_S.pieces        as pieces
               , i_S.pallets       as pallets
               , i_S.layers        as layers

          from t_soplaya.incoming_stocks i_s
                   inner join soplaya.art_registry art
                              on art.art_code = i_s.art_code
                   inner join soplaya.store_registry s
                              on s.store_code = i_s.store_code
                   inner join soplaya.product p
                              on art.id = p.art_registry_id
                                  and s.id = p.store_registry_id) new
    ON DUPLICATE KEY UPDATE product_id    = new.product_id,
                            delivery_date = new.delivery_date,
                            packs         = new.packs,
                            pieces        = new.pieces,
                            pallets       = new.pallets,
                            layers        = new.layers;
end;

