create database healthcare_db;

DROP TABLE IF EXISTS healthcare;

CREATE TABLE healthcare (
    "Name" VARCHAR(100),
    "Age" INTEGER,
    "Gender" VARCHAR(10),
    "Blood Type" VARCHAR(5),
    "Medical Condition" VARCHAR(100),
    "Date of Admission" DATE,
    "Doctor" VARCHAR(100),
    "Hospital" VARCHAR(100),
    "Insurance Provider" VARCHAR(100),
    "Billing Amount" NUMERIC(10,2),
    "Room Number" INTEGER,
    "Admission Type" VARCHAR(20),
    "Discharge Date" DATE,
    "Medication" VARCHAR(100),
    "Test Results" VARCHAR(20),
    "Length of Stay " INTEGER
);
--create patients table
CREATE TABLE patients AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY "Name") AS patient_id,
    "Name" AS name,
    "Age" AS age,
    "Gender" AS gender,
    "Blood Type" AS blood_type
FROM (SELECT DISTINCT "Name", "Age", "Gender", "Blood Type" FROM healthcare) sub;

--create doctors table
CREATE TABLE doctors AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY "Doctor") AS doctor_id,
    "Doctor" AS doctor_name
FROM (SELECT DISTINCT "Doctor" FROM healthcare) sub;

ALTER TABLE doctors ADD PRIMARY KEY (doctor_id);

ALTER TABLE patients ADD PRIMARY KEY (patient_id);

--create hospitals table
CREATE TABLE hospitals AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY "Hospital") AS hospital_id,
    "Hospital" AS hospital_name
FROM (SELECT DISTINCT "Hospital" FROM healthcare) sub;

ALTER TABLE hospitals ADD PRIMARY KEY (hospital_id);

---create insurance table
CREATE TABLE insurance AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY "Insurance Provider") AS insurance_id,
    "Insurance Provider" AS insurance_provider
FROM (SELECT DISTINCT "Insurance Provider" FROM healthcare) sub;

ALTER TABLE insurance ADD PRIMARY KEY (insurance_id);

--create admissions table
CREATE TABLE admissions AS
SELECT
    ROW_NUMBER() OVER (ORDER BY h."Date of Admission") AS admission_id,
    p.patient_id,
    d.doctor_id,
    ho.hospital_id,
    i.insurance_id,
    h."Medical Condition"        AS medical_condition,
    h."Date of Admission"        AS date_of_admission,
    h."Discharge Date"           AS discharge_date,
    h."Billing Amount"           AS billing_amount,
    h."Room Number"              AS room_number,
    h."Admission Type"           AS admission_type,
    h."Medication"               AS medication,
    h."Test Results"             AS test_results,
    h."Length of Stay "           AS length_of_stay
FROM healthcare h
JOIN patients p   ON h."Name"               = p.name
JOIN doctors d    ON h."Doctor"             = d.doctor_name
JOIN hospitals ho ON h."Hospital"           = ho.hospital_name
JOIN insurance i  ON h."Insurance Provider" = i.insurance_provider;

ALTER TABLE admissions ADD PRIMARY KEY (admission_id);

select * from patients
select * from doctors
select * from hospitals
select * from insurance
select * from admissions

-- Test JOIN between all tables
SELECT 
    p.name,
    p.age,
    p.gender,
    d.doctor_name,
    ho.hospital_name,
    i.insurance_provider,
    a.medical_condition,
    a.billing_amount,
    a.admission_type,
    a.test_results
FROM admissions a
JOIN patients  p  ON a.patient_id  = p.patient_id
JOIN doctors   d  ON a.doctor_id   = d.doctor_id
JOIN hospitals ho ON a.hospital_id = ho.hospital_id
JOIN insurance i  ON a.insurance_id = i.insurance_id
LIMIT 10;

select count(*) from admissions
SELECT COUNT(*) FROM healthcare;

-- Check duplicate names in patients
SELECT name, COUNT(*) 
FROM patients 
GROUP BY name 
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
LIMIT 10;

-- Check duplicate doctors
SELECT doctor_name, COUNT(*) 
FROM doctors 
GROUP BY doctor_name 
HAVING COUNT(*) > 1
LIMIT 10;

-- Check duplicate hospitals
SELECT hospital_name, COUNT(*) 
FROM hospitals 
GROUP BY hospital_name 
HAVING COUNT(*) > 1
LIMIT 10;

ALTER TABLE healthcare ADD COLUMN row_id SERIAL;

DROP TABLE patients CASCADE;

CREATE TABLE patients AS
SELECT 
    row_id          AS patient_id,
    "Name"          AS name,
    "Age"           AS age,
    "Gender"        AS gender,
    "Blood Type"    AS blood_type
FROM healthcare;

DROP TABLE IF EXISTS admissions CASCADE;

CREATE TABLE admissions AS
SELECT
    ROW_NUMBER() OVER (ORDER BY h.row_id) AS admission_id,
    p.patient_id,
    d.doctor_id,
    ho.hospital_id,
    i.insurance_id,
    h."Medical Condition"        AS medical_condition,
    h."Date of Admission"        AS date_of_admission,
    h."Discharge Date"           AS discharge_date,
    h."Billing Amount"           AS billing_amount,
    h."Room Number"              AS room_number,
    h."Admission Type"           AS admission_type,
    h."Medication"               AS medication,
    h."Test Results"             AS test_results,
    h."Length of Stay "          AS length_of_stay
FROM healthcare h
JOIN patients p   ON h.row_id               = p.patient_id
JOIN doctors d    ON h."Doctor"             = d.doctor_name
JOIN hospitals ho ON h."Hospital"           = ho.hospital_name
JOIN insurance i  ON h."Insurance Provider" = i.insurance_provider;
ALTER TABLE admissions ADD PRIMARY KEY (admission_id);

select * from admissions
select * from patients
select * from doctors
select * from hospitals
select * from insurance

--PATIENT AND DEMOGRAPHICS ANALYSIS
--1)What is the age distribution of patients? Which age group visits most?
select case
           when p.age between 0 and 18 then '0 - 18'
		   when p.age between 19 and 30 then '19 - 30'
		   when p.age between 31 and 45 then '31 - 45'
		   when p.age between 46 and 60 then '45 - 60'
		   when p.age between 61 and 75 then '61 - 75'
		   else '75+'
	   end as age_group,
	   count(*) as total_patients,
	   concat(round(count(*)*100.0/sum(count(*)) over(), 2), '%') as percentage
from admissions as a
left join patients as p
on a.patient_id = p.patient_id
group by age_group
order by percentage desc

--2)Which gender has higher admission rates and for which conditions?
select p.gender,
       a.medical_condition,
	   count(*) as total_conditions
from admissions a
left join patients p 
on a.patient_id = p.patient_id
group by p.gender, a.medical_condition
order by total_conditions desc

--3)What are the top 5 most common medical conditions being treated?
select medical_condition,
       count(*) as total_cases,
	   concat(round(count(*)*100.0/sum(count(*)) over(),2), '%') as percentage
from admissions
group by medical_condition
order by total_cases desc limit 5
	   
--4)Which blood group is most common among patients?
select blood_type,
       count(*) as total_patients,
	   concat(round(count(*)*100.0/sum(count(*)) over(),3), '%') as percentage
from patients
group by blood_type
order by total_patients desc
	   
--BILLING AND FINANCIAL ANALYSIS
--5)What is the average billing amount per medical condition?
select medical_condition,
       round(avg(billing_amount),2 ) as avg_billing_amount     
from admissions
group by medical_condition
order by avg_billing_amount desc
	   
--6)Which insurance provider covers the most patients?
select
       i.insurance_provider,
	   count(*) as total_patients
from insurance as i 	   
join admissions as a
on i.insurance_id = a.insurance_id
group by i.insurance_provider
order by total_patients desc

--7)Which insurance provider has the highest average billing amount?
select
       i.insurance_provider,
	   count(*) as total_patients,
	   round(avg(a.billing_amount),2) as avg_billing
from insurance as i 	   
join admissions as a
on i.insurance_id = a.insurance_id
group by i.insurance_provider
order by avg_billing desc limit 1

--8)Are there any unusually high billing cases that need investigation?
SELECT 
    p.name,
    a.medical_condition,
    i.insurance_provider,
    a.billing_amount,
    a.date_of_admission,
    a.admission_type
FROM admissions a
JOIN patients p  ON a.patient_id  = p.patient_id
JOIN insurance i ON a.insurance_id = i.insurance_id
WHERE a.billing_amount > (
    SELECT AVG(billing_amount) + 2 * STDDEV(billing_amount)
    FROM admissions
)
ORDER BY a.billing_amount DESC
LIMIT 20;

--9)Monthly Billing Trend
SELECT 
    EXTRACT(YEAR FROM a.date_of_admission)  AS year,
    EXTRACT(MONTH FROM a.date_of_admission) AS month,
    TO_CHAR(a.date_of_admission, 'Month')   AS month_name,
    ROUND(SUM(a.billing_amount)::NUMERIC, 2)  AS total_billing,
    ROUND(AVG(a.billing_amount)::NUMERIC, 2)  AS avg_billing,
    COUNT(*) AS total_admissions
FROM admissions a
GROUP BY year, month, month_name
ORDER BY year, month;

--HOSPITAL AND OPERATIONAL ANALYSIS
--10)Which hospital in the network handles the most patients?
select h.hospital_id,
       h.hospital_name,
       count(*) as total_patients
from hospitals as h
join admissions as a 
on h.hospital_id = a.hospital_id
join patients as p 
on a.patient_id = p.patient_id
group by h.hospital_id
order by total_patients desc limit 10

--11)What is the average length of stay per admission type?
select round(avg(length_of_stay),2) as avg_stay,
       admission_type,
	   MIN(discharge_date - date_of_admission) AS min_stay_days,
       MAX(discharge_date - date_of_admission) AS max_stay_days,
       COUNT(*) AS total_cases
from admissions
group by admission_type
order by avg_stay desc

--12)Which admission type is most frequent — Emergency, Elective, or Urgent?
select 
       admission_type,
       COUNT(*) AS total_admissions
from admissions
group by admission_type
order by total_admissions desc

--13)How is bed occupancy trending over months?
SELECT 
    EXTRACT(YEAR FROM date_of_admission)  AS year,
    EXTRACT(MONTH FROM date_of_admission) AS month,
    TO_CHAR(date_of_admission, 'Month')   AS month_name,
    COUNT(*) AS total_admissions,
    COUNT(DISTINCT room_number) AS rooms_occupied
FROM admissions
GROUP BY year, month, month_name
ORDER BY year, month;

--14) Hospital wise Admission Type Breakdown
SELECT 
    h.hospital_name,
    a.admission_type,
    COUNT(*) AS total_cases,
    ROUND(AVG(a.billing_amount), 2) AS avg_billing
FROM admissions a
JOIN hospitals h ON a.hospital_id = h.hospital_id
GROUP BY h.hospital_name, a.admission_type
ORDER BY h.hospital_name, total_cases DESC;

--DOCTOR PERFORMANCE ANALYSIS
--15)Which doctors are handling the highest number of patients?
select d.doctor_name,
	   count(*) as total_patients
from doctors as d 
join admissions as a
on d.doctor_id = a.doctor_id
group by d.doctor_name 
order by total_patients desc limit 10

--16)Is there any relation between the doctor and billing amount?
select d.doctor_name,
	   count(*) as total_patients,
	   sum(billing_amount) as total_billing
from doctors as d 
join admissions as a
on d.doctor_id = a.doctor_id
group by d.doctor_name 
order by total_patients desc limit 10

--17)Are certain doctors associated with specific medical conditions?
select 
    d.doctor_name,
    a.medical_condition,
    COUNT(*) AS total_cases
FROM admissions a
JOIN doctors d ON a.doctor_id = d.doctor_id
GROUP BY d.doctor_name, a.medical_condition
HAVING COUNT(*) >= 3
ORDER BY total_cases DESC
LIMIT 15;

--18)Top Doctor for Each Medical Condition
SELECT medical_condition, doctor_name, total_cases
FROM (
    SELECT 
        a.medical_condition,
        d.doctor_name,
        COUNT(*) AS total_cases,
        RANK() OVER (
            PARTITION BY a.medical_condition 
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM admissions a
    JOIN doctors d ON a.doctor_id = d.doctor_id
    GROUP BY a.medical_condition, d.doctor_name
) ranked
WHERE rnk = 1
ORDER BY total_cases DESC;

--19)Doctor performance summary
SELECT 
    d.doctor_name,
    COUNT(*) AS total_patients,
    ROUND(AVG(a.billing_amount)::NUMERIC, 2) AS avg_billing,
    ROUND(AVG(a.discharge_date - a.date_of_admission):: int, 2) AS avg_stay_days
FROM admissions a
JOIN doctors d ON a.doctor_id = d.doctor_id
GROUP BY d.doctor_name
ORDER BY total_patients DESC
LIMIT 10;

--MEDICAL AND TEST RESULT ANALYSIS
--20)What percentage of patients have abnormal vs normal test results?
SELECT 
    test_results,
    COUNT(*) AS total_cases,
    concat(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2), '%') AS percentage
FROM admissions
GROUP BY test_results
ORDER BY total_cases DESC;

--21)Is there a correlation between medical condition and test result?
SELECT 
    medical_condition,
    test_results,
    COUNT(*) AS total_cases,
    concat(ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY medical_condition), 
        2
    ), '%') AS percentage_within_condition
FROM admissions
GROUP BY medical_condition, test_results
ORDER BY medical_condition, total_cases DESC;

--22)Which conditions have the highest rate of abnormal results?
SELECT 
    medical_condition,
    COUNT(*) AS total_cases,
    SUM(CASE WHEN test_results = 'Abnormal' THEN 1 ELSE 0 END) AS abnormal_cases,
    concat(ROUND(
        SUM(CASE WHEN test_results = 'Abnormal' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ),'%') AS abnormal_percentage
FROM admissions
GROUP BY medical_condition
ORDER BY abnormal_percentage DESC;
