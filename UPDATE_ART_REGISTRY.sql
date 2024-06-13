drop procedure if exists crai.UPDATE_ART_REGISTRY;

create
    definer = tuidiadmin@`%` procedure crai.UPDATE_ART_REGISTRY()
begin

    /*
    Cancello tutti i record senza una nuova istanza
     */
    #   delete old
    #   from crai.art_registry old
    #   join t_craicommon.art_registry new on old.art_code=new.art_code
    #   where to_be_deleted=1;

    -- #########################################################################################
/*
Inserisco le nuove istanze dei record esistenti
 */

    /*
    DEP
    */
    insert into crai.dep(code, dep_code, description, insert_date, update_date)
    select distinct new.dep_code_ama      as code
                  , md5(new.dep_code_ama) as dep_code
                  , new.dep_desc_ama      as description
                  , new.insert_date
                  , new.update_date
    from t_craicommon.art_registry new
    on duplicate key update code=new.dep_code_ama
                          , description=new.dep_desc_ama
                          , update_date=new.update_date;

    /*
    SUBDEP
    */
    insert into crai.subdep (code, subdep_code, description, dep_id)
    select distinct new.subdep_code_ama      as code
                  , md5(new.subdep_code_ama) as subdep_code
                  , new.subdep_desc_ama      as description
                  , a.id                     as dep_id
    from t_craicommon.art_registry new
             join (select id, code from crai.dep) a on new.dep_code_ama = a.code
    on duplicate key update code= new.subdep_code_ama
                          , description=new.subdep_desc_ama;

    /*
    FAMILY
    */

    insert into crai.family (code, family_code, description, subdep_id)
    select distinct null        as code
                  , subdep_code as family_code
                  , null        as description
                  , a.id        as subdep_id
    from t_craicommon.art_registry new
             join (select id, code, subdep_code from crai.subdep) a on new.subdep_code_ama = a.code
    on duplicate key update family_code = subdep_code
                          , subdep_id   = a.id;

    /*
    SUBFAMILY
    */

    insert into crai.subfamily(code, subfamily_code, description, family_id)
    select distinct null          as code
                  , a.family_code as subfamily_code
                  , null          as description
                  , a.id          as family_id
    from t_craicommon.art_registry new
             join (select id, family_code from crai.family) a on md5(new.subdep_code_ama) = a.family_code
    on duplicate key update subfamily_code=a.family_code
                          , family_id     =a.id;

    /*
    GROUP
    */

    insert into crai.group(code, group_code, description, subfamily_id)
    select distinct null             as code
                  , a.subfamily_code as group_code
                  , null             as description
                  , a.id             as subfamily_id
    from t_craicommon.art_registry new
             join (select id, subfamily_code from crai.subfamily) a on md5(new.subdep_code_ama) = a.subfamily_code
    on duplicate key update group_code=a.subfamily_code
                          , subfamily_id=a.id;

    /*
    SUBGROUP
    */

    insert into crai.subgroup (code, subgroup_code, description, group_id)
    select distinct null         as code
                  , a.group_code as subgroup_code
                  , null         as description
                  , a.id         as group_id
    from t_craicommon.art_registry new
             join (select id, group_code from crai.group) a on md5(new.subdep_code_ama) = a.group_code
    on duplicate key update subgroup_code=a.group_code
                          , group_id= a.id;


    /*
    ART REGISTRY
    */

    insert into crai.art_registry (art_code, description, flg_ventilation, uom, subgroup_id,
                                   art_info)
-- Inserire tutti i campi della tabella
    select new.art_code,
           new.description,
           new.flg_ventilation,
           new.uom,
           s.id,
           new.art_info
    from t_craicommon.art_registry new
             inner join crai.subgroup s on md5(new.subdep_code_ama) = s.subgroup_code
    on duplicate key update
                         -- Inserire solo i campi variabili della tabella
                         description=new.description,
                         uom=new.uom,
                         flg_ventilation = new.flg_ventilation,
                         subgroup_id=s.id;

END;

