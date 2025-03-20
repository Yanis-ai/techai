-- テーブル1: example_data
CREATE TABLE example_data (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL
);

-- example_data テーブルにサンプルデータを挿入
INSERT INTO example_data (content) VALUES ('Hello, world!');
INSERT INTO example_data (content) VALUES ('Welcome to Flask API!');

-- テーブル2: connection_counter
CREATE TABLE connection_counter (
    id SERIAL PRIMARY KEY,
    count INT NOT NULL DEFAULT 0
);

-- connection_counter テーブルに初期データを挿入
INSERT INTO connection_counter (count) VALUES (0);
