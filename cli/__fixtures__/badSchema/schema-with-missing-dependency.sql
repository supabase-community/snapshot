DROP EXTENSION IF EXISTS isn;
-- Create table should fail because the extension providing isbn type is missing
CREATE TABLE IF NOT EXISTS movie (
    id isbn,
    uid uuid DEFAULT public.uuid_generate_v4()
);