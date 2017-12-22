CREATE SCHEMA IF NOT EXISTS spelltacular;

CREATE TABLE IF NOT EXISTS spelltacular.spelling_list (
  spelling_list_id        SERIAL PRIMARY KEY,
  name                    TEXT
);

CREATE TABLE IF NOT EXISTS spelltacular.spelling_list_entry (
  spelling_list_entry_id  SERIAL PRIMARY KEY,
  spelling_list_id        INTEGER REFERENCES spelltacular.spelling_list(spelling_list_id),
  spelling                TEXT
);
