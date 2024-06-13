drop procedure if exists crai.UPDATE_FORECAST;

create
    definer = tuidiadmin@`%` procedure crai.UPDATE_FORECAST()
begin


    drop temporary table if exists t_craicommon.forecast_full;
    create temporary table t_craicommon.forecast_full
    select avg, std_dev, art_code, store_code, reg_date, forecast_date, forecast
    from t_crai.forecast
    #     union
#     select avg, std_dev, art_code, store_code, reg_date, forecast_date, forecast
#     from t_crai2.forecast
    ;

    /*
    cancello previsioni obsolete
    */

    delete
    from crai.forecast f
    where f.reg_date < current_date;

    /*
    inserisco nuovi record
    */

    insert into crai.forecast(avg, std_dev, product_id, reg_date, forecast_date, forecast)
    select new.avg
         , new.std_dev
         , new.product_id
         , new.reg_date
         , new.forecast_date
         , new.forecast
    from (select ifnull(f.avg, 0)      as avg,
                 ifnull(f.std_dev, 0)  as std_dev,
                 p.id                  as product_id,
                 f.reg_date            as reg_date,
                 f.forecast_date       as forecast_date,
                 ifnull(f.forecast, 0) as forecast
          from t_craicommon.forecast_full f
                   inner join crai.art_registry art
                              on art.art_code = f.art_code
                   inner join crai.store_registry s
                              on s.store_code = f.store_code
                   inner join crai.product p
                              on art.id = p.art_registry_id
                                  and s.id = p.store_registry_id) new
    on duplicate key update avg           = new.avg,
                            std_dev       = new.std_dev,
                            forecast_date = new.forecast_date,
                            forecast      = new.forecast;

end;

