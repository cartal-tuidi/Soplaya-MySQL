drop procedure if exists soplaya.UPDATE_FORECAST;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_FORECAST()
begin


    drop temporary table if exists t_soplaya.forecast_full;
    create temporary table t_soplaya.forecast_full
    select avg, std_dev, seasonal_coef, art_code, store_code, reg_date, forecast_date, forecast
    from t_soplaya.forecast
    #     union
#     select avg, std_dev, art_code, store_code, reg_date, forecast_date, forecast
#     from t_soplaya2.forecast
    ;

    /*
    cancello previsioni obsolete
    */

    delete
    from soplaya.forecast f
    where f.reg_date < current_date;

    /*
    inserisco nuovi record
    */

    insert into soplaya.forecast(avg, std_dev, product_id, reg_date, forecast_date, forecast, seasonal_coef)
    select new.forecast as avg
         , new.std_dev
         , new.product_id
         , new.reg_date
         , new.forecast_date
         , new.forecast
    , new.seasonal_coef
    from (select ifnull(f.avg, 0)      as avg,
                 ifnull(f.std_dev, 0)  as std_dev,
                 p.id                  as product_id,
                 f.reg_date            as reg_date,
                 f.forecast_date       as forecast_date,
                 f.seasonal_coef as seasonal_coef,
                 ifnull(f.forecast, 0) as forecast
          from t_soplaya.forecast_full f
                   inner join soplaya.art_registry art
                              on art.art_code = f.art_code
                   inner join soplaya.store_registry s
                              on s.store_code = f.store_code
                   inner join soplaya.product p
                              on art.id = p.art_registry_id
                                  and s.id = p.store_registry_id) new
    on duplicate key update avg           = new.forecast,
                            std_dev       = new.std_dev,
                            forecast_date = new.forecast_date,
                            forecast      = new.forecast,
                            seasonal_coef      = new.seasonal_coef;

end;

