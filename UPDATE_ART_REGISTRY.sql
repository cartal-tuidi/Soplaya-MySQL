drop procedure if exists soplaya.UPDATE_ART_REGISTRY;

create
    definer = tuidiadmin@`%` procedure soplaya.UPDATE_ART_REGISTRY()
begin

    /*
    Cancello tutti i record senza una nuova istanza
     */
    #   delete old
    #   from soplaya.art_registry old
    #   join t_soplaya.art_registry new on old.art_code=new.art_code
    #   where to_be_deleted=1;

    -- #########################################################################################
/*
Inserisco le nuove istanze dei record esistenti
 */

    /*
    DEP
    */
    insert into soplaya.dep(code, dep_code, description, insert_date, update_date)
    select distinct new.dep_code      as code
                  , md5(new.dep_code) as dep_code
                  , new.dep_desc     as description
                  , new.insert_date
                  , new.update_date
    from t_soplaya.art_registry new
    on duplicate key update code=new.dep_code
                          , description=new.dep_desc
                          , update_date=new.update_date;

    /*
    SUBDEP
    */
    insert into soplaya.subdep (code, subdep_code, description, dep_id)
    select distinct new.subdep_code      as code
                  , md5(new.subdep_code) as subdep_code
                  , new.subdep_desc      as description
                  , a.id                     as dep_id
    from t_soplaya.art_registry new
             join (select id, code from soplaya.dep) a on new.dep_code = a.code
    on duplicate key update code= new.subdep_code
                          , description=new.subdep_desc;

    /*
    FAMILY
    */

    insert into soplaya.family (code, family_code, description, subdep_id)
    select distinct null        as code
                  , a.subdep_code as family_code
                  , null        as description
                  , a.id        as subdep_id
    from t_soplaya.art_registry new
             join (select id, code, subdep_code from soplaya.subdep) a on new.subdep_code = a.code
    on duplicate key update family_code = a.subdep_code
                          , subdep_id   = a.id;

    /*
    SUBFAMILY
    */

    insert into soplaya.subfamily(code, subfamily_code, description, family_id)
    select distinct null          as code
                  , a.family_code as subfamily_code
                  , null          as description
                  , a.id          as family_id
    from t_soplaya.art_registry new
             join (select id, family_code from soplaya.family) a on md5(new.subdep_code) = a.family_code
    on duplicate key update subfamily_code=a.family_code
                          , family_id     =a.id;

    /*
    GROUP
    */

    insert into soplaya.group(code, group_code, description, subfamily_id)
    select distinct null             as code
                  , a.subfamily_code as group_code
                  , null             as description
                  , a.id             as subfamily_id
    from t_soplaya.art_registry new
             join (select id, subfamily_code from soplaya.subfamily) a on md5(new.subdep_code) = a.subfamily_code
    on duplicate key update group_code=a.subfamily_code
                          , subfamily_id=a.id;

    /*
    SUBGROUP
    */

    insert into soplaya.subgroup (code, subgroup_code, description, group_id)
    select distinct null         as code
                  , a.group_code as subgroup_code
                  , null         as description
                  , a.id         as group_id
    from t_soplaya.art_registry new
             join (select id, group_code from soplaya.group) a on md5(new.subdep_code) = a.group_code
    on duplicate key update subgroup_code=a.group_code
                          , group_id= a.id;


    /*
    ART REGISTRY
    */

    insert into soplaya.art_registry (art_code, description, uom, subgroup_id,
                                   art_info)
-- Inserire tutti i campi della tabella
    select new.art_code,
           new.description,
           new.uom,
           s.id,
           new.art_info
    from t_soplaya.art_registry new
             left join soplaya.subgroup s on md5(new.subdep_code) = s.subgroup_code
    on duplicate key update
                         -- Inserire solo i campi variabili della tabella
                         description=new.description,
                         uom=new.uom,
                         subgroup_id=s.id;

END;

