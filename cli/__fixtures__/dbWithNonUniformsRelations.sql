-- Enable the UUID extension for generating UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create table_2
CREATE TABLE table_2 (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL
);

-- Create table_1
CREATE TABLE table_1 (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  geom TEXT NOT NULL,
  table_2_id UUID REFERENCES table_2(id)
);

-- Create table_3
CREATE TABLE table_3 (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  description TEXT NOT NULL,
  table_2_id UUID REFERENCES table_2(id)
);

-- Insert some data into table_2
INSERT INTO table_2 (name) VALUES
('Name1'),
('Name2'),
('Name3');

-- Insert some data into table_1
-- Note: Replace 'POINT(0 0)' with the actual geometry data you have
INSERT INTO table_1 (geom, table_2_id) VALUES
('POINT(0 0)', (SELECT id FROM table_2 WHERE name = 'Name1')),
('POINT(1 1)', (SELECT id FROM table_2 WHERE name = 'Name2')),
('POINT(2 2)', (SELECT id FROM table_2 WHERE name = 'Name3'));

-- Insert some data into table_3
INSERT INTO table_3 (description, table_2_id) VALUES
('Description1', (SELECT id FROM table_2 WHERE name = 'Name1')),
('Description2', (SELECT id FROM table_2 WHERE name = 'Name2')),
('Description3', (SELECT id FROM table_2 WHERE name = 'Name3'));

DO $$
DECLARE
   i INTEGER := 0;
   table_2_entry UUID;
BEGIN
   FOR i IN 1..10000 LOOP
       SELECT id FROM table_2 OFFSET floor(random()*3) LIMIT 1 INTO table_2_entry;
       INSERT INTO table_1 (geom, table_2_id) VALUES ('POINT(' || i || ' ' || i || ')', table_2_entry);
   END LOOP;
END $$;