SELECT *
FROM layoffs;

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, 'date', percentage_laid_off) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location,  industry, total_laid_off, 'date', percentage_laid_off, stage, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, 'date', percentage_laid_off) AS row_num
FROM layoffs_staging;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DELETE FROM layoffs_staging2 WHERE row_num > 1;


SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, 'date', percentage_laid_off) AS row_num
FROM layoffs_staging;

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT distinct industry
FROM layoffs_staging2
WHERE industry LIKE 'CRYPTO%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;


SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

SELECT `date`,
       STR_TO_DATE(`date`, '%d-%m-%Y') AS formatted_date
FROM layoffs_staging2;

SELECT `date`,
       CASE
           WHEN `date` LIKE '%-%-%' THEN STR_TO_DATE(`date`, '%d-%m-%Y')
           WHEN `date` LIKE '%/%/%' THEN STR_TO_DATE(`date`, '%m/%d/%Y')
           ELSE NULL
       END AS formatted_date
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = CASE
    WHEN TRIM(`date`) LIKE '%-%-%' THEN DATE_FORMAT(STR_TO_DATE(TRIM(`date`), '%d-%m-%Y'), '%Y-%m-%d')
    WHEN TRIM(`date`) LIKE '%/%/%' THEN DATE_FORMAT(STR_TO_DATE(TRIM(`date`), '%m/%d/%Y'), '%Y-%m-%d')
    ELSE `date`
END;


SELECT date
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry is NULL
OR industry = ''; 

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry is NULL OR t1.industry = '')
AND t2.industry is not NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE (t1.industry is NULL OR t1.industry = '')
AND t2.industry is not NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
ORDER BY 1;


ALTER TABLE 
layoffs_staging2
DROP column row_num;

SELECT MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

SELECT SUBSTR(`date`,1,7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTR(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

WITH Rolling_Total AS
(
SELECT SUBSTR(`date`,1,7) AS `Month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTR(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `Month`, total_off, SUM(total_off) OVER(ORDER BY `Month`) AS roll
FROM Rolling_Total;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

WITH Company_Year(company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS(
SELECT *, dense_rank() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
