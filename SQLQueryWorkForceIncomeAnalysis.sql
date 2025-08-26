-- <<. Create Database
CREATE DATABASE WorkforceIncomeAnalysis;

USE WorkforceIncomeAnalysis;

--<< QUERY TO CREATE TABLE

CREATE TABLE salaries (
    work_year INT,
    experience_level VARCHAR(5),
    employment_type VARCHAR(5),
    job_title VARCHAR(200),
    salary INT,
    salary_currency VARCHAR(10),
    salary_in_usd INT,
    employee_residence VARCHAR(10),
    remote_ratio INT,
    company_location VARCHAR(10),
    company_size VARCHAR(3)
);


--<< QUERY TO INSERT DATA
SELECT * FROM salaries

BULK INSERT salaries
FROM 'C:\Users\Dataset_salaries.csv'
WITH (
    FIRSTROW = 2,               -- Skip header row
    FIELDTERMINATOR = ',',      -- Columns separated by comma
    ROWTERMINATOR = '\n',       -- New line ends each row
    TABLOCK
);


SELECT * FROM salaries


-- TASK 1. Job market by company size in 2021 (if 2021 data exists)

SELECT 
    company_size,
    COUNT(*) as employee_count
FROM salaries
WHERE work_year = 2021
GROUP BY company_size
ORDER BY employee_count DESC;


select * from salaries
where work_year = 2023

-- Task 2: Top 3 job titles with the highest average salary for part-time positions in 2023

SELECT TOP 3
    job_title,
    COUNT(*) as employee_count,
    AVG(salary_in_usd) as avg_salary
FROM salaries
WHERE employment_type = 'PT' 
    AND work_year = 2023
GROUP BY job_title
HAVING COUNT(*) > 50
ORDER BY avg_salary DESC;


-- Task 3: Countries where mid-level salary is higher than overall mid-level salary in 2023

SELECT 
    employee_residence as country,
    COUNT(*) as mid_level_employees,
    AVG(salary_in_usd) as country_avg_salary
FROM salaries
WHERE experience_level = 'MI' AND work_year = 2023
GROUP BY employee_residence
HAVING AVG(salary_in_usd) > (
    SELECT AVG(salary_in_usd) 
    FROM salaries 
    WHERE experience_level = 'MI' AND work_year = 2023
)
ORDER BY country_avg_salary DESC;

SELECT company_location, AVG(salary_in_usd) AS avg_salary
FROM salaries
WHERE experience_level = 'SE' 
  AND work_year = 2023
GROUP BY company_location
ORDER BY avg_salary DESC;


--TASK 4: Highest and lowest average salary locations for SE in 2023
SELECT company_location, avg_salary, 'Highest' AS Category
FROM (
    SELECT TOP 1 company_location, AVG(salary_in_usd) AS avg_salary
    FROM salaries
    WHERE experience_level = 'SE' AND work_year = 2023
    GROUP BY company_location
    ORDER BY AVG(salary_in_usd) DESC
) AS High

UNION ALL

SELECT company_location, avg_salary, 'Lowest' AS Category
FROM (
    SELECT TOP 1 company_location, AVG(salary_in_usd) AS avg_salary
    FROM salaries
    WHERE experience_level = 'SE' AND work_year = 2023
    GROUP BY company_location
    ORDER BY AVG(salary_in_usd) ASC
) AS Low;


--TASK 5: Salary growth rates by job title (2023 vs 2024)
SELECT 
    job_title,
    CAST(
        ROUND(
            ((AVG(CASE WHEN work_year = 2024 THEN salary_in_usd END) -
              AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END)) * 100.0 /
              AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END)), 2
        ) AS DECIMAL(10,2)
    ) AS growth_rate_percentage
FROM salaries
WHERE work_year IN (2023, 2024)
GROUP BY job_title
----If a job_title exists only in 2023 or only in 2024 (not both), then one of those averages is NULL. 
-----To see only job titles that exist in both 2023 & 2024 add the following line to  the query
HAVING COUNT(DISTINCT work_year) = 2;


-- TASK 6: Top 3 countries with the highest salary growth for entry-level roles (2020 → 2023)
SELECT TOP 3
    employee_residence AS country,
    CAST(
        ((AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) -
          AVG(CASE WHEN work_year = 2020 THEN salary_in_usd END)) * 100.0 /
          AVG(CASE WHEN work_year = 2020 THEN salary_in_usd END)) 
        AS DECIMAL(10,2)
    ) AS growth_rate_percentage
FROM salaries
WHERE work_year IN (2020, 2023)
  AND experience_level = 'EN'
GROUP BY employee_residence
HAVING COUNT(*) > 50
ORDER BY growth_rate_percentage DESC;
--Ih the query is returning only 1 country, it means most countries in the dataset
--don’t have both 2020 and 2023 salary data for entry-level (EN) employees.


-- TASK 7: Update remote_ratio for employees earning > $90,000 in US and AU
UPDATE salaries
SET remote_ratio = 100
WHERE salary_in_usd > 90000
AND employee_residence IN ('US', 'AU');


--Query to check the results
SELECT * FROM salaries
WHERE salary_in_usd > 90000 AND 
employee_residence IN ('US', 'AU');


-- TASK 8: Update salaries in 2024 based on experience level
UPDATE salaries
SET salary_in_usd = 
    CASE experience_level
        WHEN 'SE' THEN CAST(salary_in_usd * 1.22 AS INT) -- 22% increase
        WHEN 'MI' THEN CAST(salary_in_usd * 1.30 AS INT) -- 30% increase
        WHEN 'EN' THEN CAST(salary_in_usd * 1.25 AS INT) -- 25% increase (example)
        WHEN 'EX' THEN CAST(salary_in_usd * 1.20 AS INT) -- 20% increase (example)
        ELSE salary_in_usd
    END
WHERE work_year = 2024;



-- TASK 9: Identify which year had the highest average salary for each job title
SELECT job_title, work_year AS year_with_highest_avg_salary, AVG_Salary
FROM (
    SELECT 
        job_title,
        work_year,
        AVG(salary_in_usd) AS AVG_Salary,
        ROW_NUMBER() OVER (PARTITION BY job_title ORDER BY AVG(salary_in_usd) DESC) AS rn
    FROM salaries
    GROUP BY job_title, work_year
) AS Results
WHERE rn = 1;

-- TASK 10: Percentage of full-time and part-time employees for each job title
SELECT 
    job_title,
    CAST(100.0 * SUM(CASE WHEN employment_type = 'FT' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS full_time_percentage,
    CAST(100.0 * SUM(CASE WHEN employment_type = 'PT' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS part_time_percentage
FROM salaries
GROUP BY job_title
ORDER BY job_title;


-- TASK 11: Countries offering full remote work for managers earning > $90,000
SELECT 
    employee_residence AS country,
    COUNT(*) AS manager_count
FROM salaries
WHERE job_title LIKE '%Manager%'
  AND salary_in_usd > 90000
  AND remote_ratio = 100
GROUP BY employee_residence
ORDER BY manager_count DESC;


-- TASK 12: Top 5 countries with the most large companies
SELECT TOP 5
    company_location AS country,
    COUNT(*) AS large_company_count
FROM salaries
WHERE company_size = 'L'
GROUP BY company_location
ORDER BY large_company_count DESC;



-- TASK 13: Percentage of fully remote employees earning more than $100,000
SELECT 
    CAST(100.0 * COUNT(CASE WHEN remote_ratio = 100 AND
    salary_in_usd > 100000 THEN 1 END) 
         / COUNT(*) AS DECIMAL(5,2)) AS percentage_fully_remote_over_100k
FROM salaries;



-- TASK 14: Locations where entry-level average salaries exceed market average
WITH MarketAvg AS (
    SELECT AVG(salary_in_usd) AS market_avg
    FROM salaries
    WHERE experience_level = 'EN'
)
SELECT 
    employee_residence AS location,
    CAST(AVG(salary_in_usd) AS DECIMAL(10,2)) AS avg_entry_level_salary
FROM salaries, MarketAvg
WHERE experience_level = 'EN'
GROUP BY employee_residence, market_avg
HAVING AVG(salary_in_usd) > market_avg
ORDER BY avg_entry_level_salary DESC;


-- TASK 15: Countries paying the maximum average salary for each job title (no CTE)
SELECT job_title, country, avg_salary
FROM (
    SELECT 
        job_title,
        employee_residence AS country,
        AVG(salary_in_usd) AS avg_salary,
        RANK() OVER (PARTITION BY job_title ORDER BY AVG(salary_in_usd) DESC) AS rnk
    FROM salaries
    GROUP BY job_title, employee_residence
) t
WHERE rnk = 1
ORDER BY job_title;


-- TASK 16: Countries with sustained salary growth over the last 3 years (with y1, y2, y3 shown)
WITH YearlyAvg AS (
    SELECT 
        employee_residence AS country,
        work_year,
        AVG(salary_in_usd) AS avg_salary
    FROM salaries
    WHERE work_year IN (2021, 2022, 2023)
    GROUP BY employee_residence, work_year
),
Ranked AS (
    SELECT 
        country,
        work_year,
        avg_salary,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY work_year) AS yr_rank
    FROM YearlyAvg
)
SELECT 
    country,
    CAST(MAX(CASE WHEN yr_rank = 1 THEN avg_salary END) AS DECIMAL(10,2)) AS avg_2021,
    CAST(MAX(CASE WHEN yr_rank = 2 THEN avg_salary END) AS DECIMAL(10,2)) AS avg_2022,
    CAST(MAX(CASE WHEN yr_rank = 3 THEN avg_salary END) AS DECIMAL(10,2)) AS avg_2023
FROM Ranked
GROUP BY country
HAVING 
    MAX(CASE WHEN yr_rank = 1 THEN avg_salary END) 
      < MAX(CASE WHEN yr_rank = 2 THEN avg_salary END)
    AND
    MAX(CASE WHEN yr_rank = 2 THEN avg_salary END) 
      < MAX(CASE WHEN yr_rank = 3 THEN avg_salary END)
ORDER BY country;



-- TASK 17: Percentage of fully remote work by experience level (2021 vs 2024)
SELECT 
    experience_level,
    CAST(100.0 * SUM(CASE WHEN work_year = 2021 AND remote_ratio = 100 THEN 1 ELSE 0 END) 
         / NULLIF(SUM(CASE WHEN work_year = 2021 THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS pct_remote_2021,
    CAST(100.0 * SUM(CASE WHEN work_year = 2024 AND remote_ratio = 100 THEN 1 ELSE 0 END) 
         / NULLIF(SUM(CASE WHEN work_year = 2024 THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS pct_remote_2024
FROM salaries
WHERE work_year IN (2021, 2024)
GROUP BY experience_level
ORDER BY experience_level;


-- TASK 18: Average salary increase percentage by experience level and job title (2023 to 2024)
SELECT 
    experience_level,
    job_title,
    CAST(AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS DECIMAL(10,2)) AS avg_salary_2023,
    CAST(AVG(CASE WHEN work_year = 2024 THEN salary_in_usd END) AS DECIMAL(10,2)) AS avg_salary_2024,
    CAST(
        ( (AVG(CASE WHEN work_year = 2024 THEN salary_in_usd END) 
          - AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END)) * 100.0
          / NULLIF(AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END),0)
        ) AS DECIMAL(5,2)
    ) AS pct_increase
FROM salaries
WHERE work_year IN (2023, 2024)
GROUP BY experience_level, job_title
ORDER BY experience_level, job_title;


