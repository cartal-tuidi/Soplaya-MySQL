drop procedure if exists soplaya.UPDATE_ANOMALIES;

create procedure soplaya.UPDATE_ANOMALIES()
begin

    ############ INTERMEDIATE PREDICTIONS ##################
    insert into soplaya.intermediate_prediction(product_id, reg_date, day_of_week, sum_sold, anomaly_quantity,
                                                anomaly_weight, seasonal_coef)
    select p.id
         , reg_date
         , day_of_week
         , sum_sold
         , anomaly_quantity
         , anomaly_weight
         , seasonal_coef
    from product p
             inner join art_registry ar on p.art_registry_id = ar.id
             inner join soplaya.store_registry s on p.store_registry_id = s.id
             inner join t_soplaya.intermediate_prediction i on i.art_code = ar.art_code and i.store_code = s.store_code
    on duplicate key update reg_date         = i.reg_date
                          , day_of_week      = i.day_of_week
                          , sum_sold         = i.sum_sold
                          , anomaly_quantity = i.anomaly_quantity
                          , anomaly_weight   = i.anomaly_weight
                          , seasonal_coef    = i.seasonal_coef;

############ SALES_ANOMALIES  ##################

    insert into soplaya.sales_anomaly(product_id, qty,
                                      reg_date,
                                      sales_anomaly_code,
                                      to_ignore,
                                      client_registry_id,
                                      is_tuidi)
    select p.id
         , i.qty
         , i.reg_date
         , concat(ar.art_code,'-',i.store_code,'-',c.client_code,'-',reg_date) as sales_anomaly_code
         , i.to_ignore
         , c.id
         , i.is_tuidi
    from product p
             inner join art_registry ar on p.art_registry_id = ar.id
             inner join soplaya.store_registry s on p.store_registry_id = s.id
             inner join t_soplaya.anomalies_to_push i on i.art_code = ar.art_code and i.store_code = s.store_code
             inner join soplaya.client_registry c on c.client_code = i.client_code
    on duplicate key update reg_date  = i.reg_date
                          , qty       = i.qty
                          , to_ignore = i.to_ignore
                          , is_tuidi  = i.is_tuidi;

END

