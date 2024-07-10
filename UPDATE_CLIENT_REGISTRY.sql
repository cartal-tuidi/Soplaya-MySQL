drop procedure if exists soplaya.UPDATE_CLIENT_REGISTRY;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_CLIENT_REGISTRY()
begin

    #   Cancello tutti i record senza una nuova istanza

    delete old
    from soplaya.client_registry old
             join t_soplaya.client_registry new on old.client_code = new.client_code
    where to_be_deleted = 1;


#Inserisco le nuove istanze dei record esistenti

    insert into soplaya.client_registry(client_code,
                                        business_name,
                                        email,
                                        address,
                                        tax_code)
-- Inserire tutti i campi della tabella
    select new.client_code,
           new.business_name,
           new.email,
           new.address,
           new.tax_code
    from t_soplaya.client_registry new
    on duplicate key
        update
            -- Inserire solo i campi variabili della tabella
            client_code= new.client_code,
            business_name= new.business_name,
            email= new.email,
            address= new.address,
            tax_code= new.tax_code;

END;

