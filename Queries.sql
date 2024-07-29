1)
  A)CREATE PROCEDURE GetPatientDetailsAndTotalAmount
    @doctor_id INT
AS
BEGIN
    SELECT
        p.patient_id,
        p.name,
        p.age,
        p.gender,
        p.address,
        p.disease,
        bill_total.room_charge_total + lab_total.lab_charge_total AS total_amount
    FROM
        Patient p
    LEFT JOIN (
        SELECT
            patient_id,
            SUM(room_charge * no_of_days) AS room_charge_total
        FROM
            Bill
        WHERE
            doctor_id = @doctor_id
        GROUP BY
            patient_id
    ) bill_total ON p.patient_id = bill_total.patient_id
    LEFT JOIN (
        SELECT
            patient_id,
            SUM(amount) AS lab_charge_total
        FROM
            Laboratory
        WHERE
            doctor_id = @doctor_id
        GROUP BY
            patient_id
    ) lab_total ON p.patient_id = lab_total.patient_id
    WHERE
        p.doctor_id = @doctor_id;
END;

CREATE PROCEDURE GetPatientDetailsAndTotalAmount1
    @doctor_id INT
AS
BEGIN
    SELECT
        p.patient_id,
        p.name,
        p.age,
        p.gender,
        p.address,
        p.disease,
        COALESCE(SUM(b.room_charge * b.no_of_days), 0) + COALESCE(SUM(l.amount), 0) AS total_amount
    FROM
        Patient p
    LEFT JOIN Bill b ON p.patient_id = b.patient_id AND b.doctor_id = @doctor_id
    LEFT JOIN Laboratory l ON p.patient_id = l.patient_id AND l.doctor_id = @doctor_id
    WHERE
        p.doctor_id = @doctor_id
    GROUP BY
        p.patient_id, p.name, p.age, p.gender, p.address, p.disease;
END;

B)
CREATE PROCEDURE GetNthHighestAmountPaidPatient
    @nth INT,
    @patient_id INT OUTPUT,
    @patient_name VARCHAR(255) OUTPUT
AS
BEGIN
    WITH PatientAmounts AS (
        SELECT
            p.patient_id,
            p.name,
            SUM(b.room_charge * b.no_of_days) + SUM(l.amount) AS total_amount
        FROM
            Patient p
        LEFT JOIN Bill b ON p.patient_id = b.patient_id
        LEFT JOIN Laboratory l ON p.patient_id = l.patient_id
        GROUP BY
            p.patient_id, p.name
    ),
    RankedPatients AS (
        SELECT
            patient_id,
            name,
            total_amount,
            ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS rn
        FROM
            PatientAmounts
    )
    SELECT
        @patient_id = patient_id,
        @patient_name = name
    FROM
        RankedPatients
    WHERE
        rn = @nth;
END;


CREATE PROCEDURE GetNthHighestAmountPaidPatient1
    @nth INT,
    @patient_id INT OUTPUT,
    @patient_name VARCHAR(255) OUTPUT
AS
BEGIN
    ;WITH RankedPatients AS (
        SELECT
            p.patient_id,
            p.name,
            SUM(b.room_charge * b.no_of_days) + SUM(l.amount) AS total_amount,
            ROW_NUMBER() OVER (ORDER BY SUM(b.room_charge * b.no_of_days) + SUM(l.amount) DESC) AS rn
        FROM
            Patient p
        LEFT JOIN Bill b ON p.patient_id = b.patient_id
        LEFT JOIN Laboratory l ON p.patient_id = l.patient_id
        GROUP BY
            p.patient_id, p.name
    )
    SELECT
        @patient_id = patient_id,
        @patient_name = name
    FROM
        RankedPatients
    WHERE
        rn = @nth;
END;
2)
SELECT
    ord_date,
    SUM(purch_amt) AS total_amount
FROM
    Orders
GROUP BY
    ord_date
HAVING
    SUM(purch_amt) >= (SELECT MAX(purch_amt) + 1000.00
                       FROM Orders o
                       WHERE o.ord_date = Orders.ord_date);
3)
SELECT
    e.emp_fname,
    e.emp_lname
FROM
    emp_details e
JOIN
    emp_department d ON e.emp_dept = d.DPT_CODE
WHERE
    d.SANCT_AMOUNT = (
        SELECT DISTINCT SANCT_AMOUNT
        FROM emp_department
        ORDER BY SANCT_AMOUNT
        OFFSET 1 ROWS FETCH NEXT 1 ROW ONLY
    );

WITH DepartmentSanction AS (
    SELECT
        DPT_CODE,
        SANCT_AMOUNT,
        DENSE_RANK() OVER (ORDER BY SANCT_AMOUNT ASC) AS dr
    FROM
        emp_department
),
SecondLowestDept AS (
    SELECT
        DPT_CODE
    FROM
        DepartmentSanction
    WHERE
        dr = 2
)
SELECT
    e.emp_fname,
    e.emp_lname
FROM
    emp_details e
JOIN
    SecondLowestDept d ON e.emp_depti = d.DPT_CODE;
5)
DECLARE @FilterColumn VARCHAR(20) = 'IsArchive'; 

SELECT *
FROM YourTable
WHERE
    (
        (@FilterColumn = 'IsArchive' AND IsArchive = 0 AND IsActive = 1)
        OR
        (@FilterColumn = 'IsDeleted' AND IsDeleted = 0 AND IsActive = 0)
    );
6)
SELECT H.hacker_id,H.name,SUM(M) AS S 
  FROM Hackers H 
  JOIN
(SELECT hacker_id,challenge_id,MAX(score) AS M 
  FROM Submissions 
  WHERE score > 0 
  GROUP BY hacker_id,challenge_id) R 
ON H.hacker_id = R.hacker_id 
  GROUP BY H.hacker_id,H.name  
  ORDER BY S DESC,H.hacker_id ;
7)
SELECT 
    CASE
        WHEN G.Grade >= 8 THEN S.Name
        ELSE 'NULL'
    END AS Name,
    G.Grade,
    S.Marks
FROM Students S
JOIN Grades G 
    ON S.Marks BETWEEN G.Min_Mark AND G.Max_Mark
ORDER BY 
    G.Grade DESC,
    CASE
        WHEN G.Grade >= 8 THEN S.Name
        ELSE NULL
    END,
    CASE
        WHEN G.Grade < 8 THEN S.Marks
        ELSE NULL
    END;
8)SELECT MIN(Start_Date), DATEADD(DAY, 1, MAX(Start_Date))
FROM Tasks 
GROUP BY 
    DATEDIFF(DAY, Task_ID, Start_Date)
ORDER BY 
    DATEDIFF(DAY, MIN(Start_Date), MAX(Start_Date)), MIN(Start_Date)
