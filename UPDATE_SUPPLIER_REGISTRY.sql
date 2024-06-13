drop procedure if exists soplaya.UPDATE_SUPPLIER_REGISTRY;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_SUPPLIER_REGISTRY()
begin

    /*
 Salvo le chiavi da eliminare nel sync db test
 */

    /*
    Cancello tutti i record senza una nuova istanza
     */
    delete old
    from soplaya.supplier_registry old
             join t_soplaya.supplier_registry new on old.supplier_code = new.supplier_code
    where to_be_deleted = 1;

    -- #########################################################################################
/*Inserisco le nuove istanze dei record esistenti
 */
    insert into soplaya.supplier_registry (supplier_code, business_name, tax_code, email, address)
-- Inserire tutti i campi della tabella
    select new.supplier_code, new.business_name, new.tax_code, new.email, new.address
    from t_soplaya.supplier_registry new
    where to_be_deleted = 0
    on duplicate key
        update
            -- Inserire solo i campi variabili della tabella
            business_name= new.business_name,
            tax_code= new.tax_code,
            email=new.email;


END;

