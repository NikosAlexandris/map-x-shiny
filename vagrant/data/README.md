
# psql notes



## backup


```sh
#
# set variables
#
fileDump="mapx.sql"
charMessage="Backup "$(date)
pathVm="/home/fred/projects/map-x/vagrant/map-x-full/"
pathDump="data/pgdump/"
#
# dump db
#
cd $pathVm
vagrant ssh -c "sudo su - postgres -c 'pg_dump -U postgres -d mapx > /tmp/$fileDump' && cp /tmp/$fileDump /vagrant/data/pgdump/$fileDump"
#
#  commit changes
#
cd $pathDump
git add $fileDump
git commit -m "$charMessage"
```


## jsonb note

### example select all member of a group

```sql
select id, name, grp from (select id, name, jsonb_array_elements(data->'group') as grp from tmp_users ) t where t.grp->>0 IN ('admin','public');
```

### check if there is a least one match ( exists)


```sql
select exists (
    select ln from 
    (
     SELECT un, ug
     FROM   
     ( 
      SELECT data->>'name'::text AS un,
      json_array_elements( data -> 'group')::text::int AS ug
      FROM   tmp_users 
     ) t
     WHERE  t.un::text = 'james'
    ) usr INNER JOIN
    (
     SELECT ln, lg
     FROM   
     (
      SELECT data->>'layer'::text AS ln,
      jsonb_array_elements(data -> 'group')::text::int AS lg 
      FROM tmp_layers 
     ) l
     WHERE l.ln = 'a'
    ) lay  
ON (
    usr.ug = lay.lg) 
  );


  ```



