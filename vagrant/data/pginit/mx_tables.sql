
/*
mx_users : table of user 

 */


DROP TABLE IF EXISTS mx_users ;

create table mx_users (
  id serial unique,
  username citext unique,
  email citext unique,
  key text,
  validated boolean,
  hidden boolean,
  date_validated timestamp,
  date_hidden timestamp,
  date_last_visit timestamp,
  data jsonb
);



ALTER TABLE mx_users OWNER TO mapxw;


create table if not exists mx_views (
  id text unique not null,
  country text,
  title text,
  class text,
  layer text,
  editor integer,
  reviewer integer,
  revision integer,
  validated boolean,
  archived  boolean,
  date_created timestamp with time zone,
  date_modified timestamp with time zone,
  date_validated timestamp with time zone,
  date_archived timestamp with time zone,
  style jsonb,
  visibility jsonb
);



ALTER TABLE mx_views OWNER TO mapxw;


create table if not exists mx_layers (
  country text,
  layer text,
  class text,
  tags text ,
  editor integer,
  reviewer integer,
  revision integer,
  validated boolean,
  archived  boolean,
  date_created timestamp with time zone,
  date_archived timestamp with time zone,
  date_modified timestamp with time zone,
  date_validated timestamp with time zone,
  meta jsonb,
  visibility jsonb default '["public"]'
);



ALTER TABLE mx_layers OWNER TO mapxw;


create table if not exists mx_story_maps (
  id text unique,
  country text,
  name text,
  description text,
  editor integer,
  reviewer integer,
  revision integer,
  validated boolean,
  archived  boolean,
  date_created timestamp with time zone,
  date_modified timestamp with time zone,
  date_validated timestamp with time zone,
  date_archived timestamp with time zone,
  visibility jsonb,
  content jsonb
);



ALTER TABLE mx_story_maps OWNER TO mapxw;


create table if not exists mx_polygon_of_interest (
  id text unique,
  editor integer,
  country text,
  layer text,
  type text,
  archived  boolean,
  date_created timestamp with time zone,
  date_modified timestamp with time zone,
  date_archived timestamp with time zone,
  visibility jsonb,
  geojson_mask jsonb,
  geojson_result jsonb
);



ALTER TABLE mx_polygon_of_interest OWNER TO mapxw;
