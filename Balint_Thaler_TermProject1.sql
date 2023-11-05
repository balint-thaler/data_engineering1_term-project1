USE imdb_small;

-- the original data table contains gender only as M/F values. To be able to calculate with this in an easier way, I create a new column called gender_id which is simply 1 for Male and 0 for female.
ALTER TABLE actors
ADD COLUMN gender_id BOOLEAN AFTER gender;
UPDATE actors 
SET 
gender_id =
CASE WHEN gender = "M" THEN 1 ELSE 0 END;

-- First we create the genre_data table to set up its structure and fill it with the distinct genre values from the movies_genres table
DROP TABLE IF EXISTS genre_data;
CREATE TABLE genre_data (
    genre VARCHAR(255),  
    average_male_ratio FLOAT(10),
    average_rank FLOAT(10),
    average_movie_age FLOAT(10)
);
INSERT INTO genre_data (genre, average_male_ratio, average_rank, average_movie_age)
SELECT DISTINCT t4.genre, 0.0, 0.0, 0.0
FROM movies_genres AS t4
ORDER BY genre;


-- The stored procedure fills the genre_data table with data from the other tables 
USE imdb_small;
DROP PROCEDURE IF EXISTS creategenredata;
DELIMITER //
CREATE PROCEDURE creategenredata()
BEGIN

	UPDATE genre_data AS g_d
    SET 
     g_d.average_male_ratio = (
            SELECT ROUND(AVG(t1.gender_id), 3)
            FROM actors AS t1
            INNER JOIN roles AS t2 ON t1.id = t2.actor_id
            INNER JOIN movies AS t3 ON t2.movie_id = t3.id
            WHERE t3.id IN (SELECT t4.movie_id FROM movies_genres AS t4 WHERE t4.genre = g_d.genre)
        ),
        g_d.average_rank = (
            SELECT ROUND(AVG(t3.rank), 3)
            FROM movies AS t3
            WHERE t3.id IN (SELECT t4.movie_id FROM movies_genres AS t4 WHERE t4.genre = g_d.genre)
        ),
        g_d.average_movie_age = (
            SELECT ROUND(YEAR(CURDATE()) - AVG(t3.year), 1)
            FROM movies AS t3
            WHERE t3.id IN (SELECT t4.movie_id FROM movies_genres AS t4 WHERE t4.genre = g_d.genre)
        )
        order by genre;
END //
DELIMITER ;

-- For the 5 major studios, 5 different views are created that represent the data of the genres in which each studio creates the most movies
DROP VIEW IF EXISTS Disney;
CREATE VIEW `Disney` AS
SELECT * FROM genre_data where genre IN ("Animation", "Family", "Sci-Fi")
ORDER BY genre;

DROP VIEW IF EXISTS WarnerBros;
CREATE VIEW `WarnerBros` AS
SELECT * FROM genre_data where genre IN ("Action", "Drama", "Fantasy", "Sci-Fi")
ORDER BY genre;

DROP VIEW IF EXISTS Paramount;
CREATE VIEW `Paramount` AS
SELECT * FROM genre_data where genre IN ("Action", "Adventure", "Horror", "Sci-Fi")
ORDER BY genre;

DROP VIEW IF EXISTS Universal;
CREATE VIEW `Universal` AS
SELECT * FROM genre_data where genre IN ("Action", "Comedy", "Horror")
ORDER BY genre;

DROP VIEW IF EXISTS Sony;
CREATE VIEW `Sony` AS
SELECT * FROM genre_data where genre IN ("Action", "Comedy", "Animation", "Sci-Fi")
ORDER BY genre;

-- Create trigger that calls the stored procedure and updates the genre_data tables with the new value(s).
DROP TRIGGER IF EXISTS movie_insert; 
DELIMITER $$
CREATE TRIGGER movie_insert
AFTER INSERT
ON movies_genres FOR EACH ROW
BEGIN
	CALL creategenredata();
END $$
DELIMITER ;

-- Sample value inserts that fire the trigger:
-- INSERT INTO movies VALUES(1234567, "test movie", 2, 10000);
-- INSERT INTO movies_genres VALUES(1234567, "Action");

-- deletion commands to delete manually added values for trigger testing
-- DELETE from movies where id=1234567;
-- DELETE from movies_genres where movie_id=1234567;


