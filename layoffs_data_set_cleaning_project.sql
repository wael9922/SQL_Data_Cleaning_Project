-- SQL Project - Data Cleaning


-- Imported the data into a table layoffs from CSV file
SELECT * from layoffs;

-- creating a duplicate table to preserve the raw data
CREATE TABLE layoffs_dup LIKE layoffs;
-- Copying the data to the new table
INSERT INTO layoffs_dup 
SELECT * FROM layoffs;
--  1.Removing Duplicates
-- Creating CTE to check for duplicate rows using window function Row_Number()
-- This CTE will return the duplicate rows
-- Each duplicate row will have a row number greater than 1
WITH duplicate_check_cte AS(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off,
    percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_dup)
SELECT * FROM duplicate_check_cte
WHERE row_num>1;

-- Creating third table add the row number column 
CREATE TABLE `layoffs_final` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- inserting the data with the row numbers
INSERT INTO layoffs_final 
	SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off,
    percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_dup;

-- Deleting the duplicate rows using the row_num column to identify them
DELETE FROM layoffs_final 
WHERE row_num > 1;

SELECT * FROM layoffs_final;

--  2.Standardizing Data
-- Checking the company column for any cleaning needed
SELECT DISTINCT company FROM layoffs_final
ORDER BY 1;
-- Some of the companies name started with spaces to remove the space I used TRIM()
UPDATE layoffs_final
SET company = TRIM(company);

SELECT DISTINCT industry FROM layoffs_final
ORDER BY 1;
-- The previous query showed that there is null and blank values in the industry column 
-- same industry with different naming 
-- Set blanks to nulls because it's easier to work with
UPDATE layoffs_final
SET industry = null
WHERE industry = "";
-- standardizing the Crypto industry
UPDATE layoffs_final
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

SELECT * From layoffs_final
WHERE industry IS NULL;

-- now we need to populate those nulls if possible
-- Checking some of companies that have null value in the industry column
SELECT * FROM layoffs_final
WHERE company LIKE 'Bally%';

SELECT * FROM layoffs_final
WHERE company LIKE 'airbnb%';
-- the previous query we noticed that Airbnb is in the travel industry from other layoffs for the same company
 
-- if there is another row like Airbnb case,we can use it to update the null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all
UPDATE layoffs_final t1
JOIN layoffs_final t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- it looks like Bally's was the only one without a populated row to populate this null
SELECT * From layoffs_final
WHERE industry IS NULL;
-- Noticed some values ended with . and it made it a distinct value due to it
SELECT distinct country FROM layoffs_final
ORDER BY 1;
-- Standardizing the country column by removing the .
UPDATE layoffs_final
SET country = REPLACE(country,".","");

-- Fix the date column
UPDATE layoffs_final
SET date = STR_TO_DATE(date, '%m/%d/%Y');
-- date column is text, convering it to date type
ALTER TABLE layoffs_final
MODIFY COLUMN date DATE;

SELECT * FROM layoffs_final;
--  3. Removing unnecessary columns and rows
-- Return the rows that are considered useless to my analysis
SELECT * FROM layoffs_final
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Delete Useless data
DELETE FROM layoffs_final
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_final;
-- Now after the cleaning process is completed I don't need the row_num column anymore 
ALTER TABLE layoffs_final
DROP COLUMN row_num;

-- Now our data is cleaned and ready to be analyzed
SELECT * FROM layoffs_final;
