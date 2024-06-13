drop procedure if exists soplaya.UPDATE_STORE_REGISTRY;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_STORE_REGISTRY()
begin

    #   Cancello tutti i record senza una nuova istanza

    delete old
    from soplaya.store_registry old
             join t_soplaya.store_registry new on old.store_code = new.store_code
    where to_be_deleted = 1;


#Inserisco le nuove istanze dei record esistenti

    insert into soplaya.store_registry (store_code, business_name, address, tax_code, email)
-- Inserire tutti i campi della tabella
    select new.store_code, new.business_name, new.address, new.tax_code, new.email
    from t_soplaya.store_registry new
    on duplicate key
        update
             -- Inserire solo i campi variabili della tabella
            business_name= new.business_name
             , address= new.address
             , tax_code= new.tax_code
             , email     = new.email;

END;

