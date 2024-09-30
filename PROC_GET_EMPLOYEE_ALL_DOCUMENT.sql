create or replace PROCEDURE  "PROC_GET_EMPLOYEE_ALL_DOCUMENT" 
(
 P_EmployeeId IN number,
 C_Details out SYS_REFCURSOR
)
AS 
BEGIN

 OPEN C_Details FOR
      SELECT
    d.code AS Code,
    bd.filepath as FilePath
    FROM tbl_basic_documents  bd
        join tbl_documents  d on d.id = bd.documentid
    where Employee_ID =   P_EmployeeId  
     union ALL
    SELECT
    d.code AS Code,
    bd.filepath as FilePath
    FROM tbl_general_documents bd
        join tbl_documents  d on d.id = bd.documentid
    where Employee_ID =  P_EmployeeId        
       union ALl 
    SELECT
    d.code AS Code,
    bd.filepath as FilePath
    FROM tbl_bank_documents bd
        join tbl_documents  d on d.id = bd.documentid
    where Employee_ID =  P_EmployeeId   
    union ALl
    SELECT
    d.code AS Code,
    bd.filepath as FilePath
    FROM tbl_education_documents bd
        join tbl_documents  d on d.id = bd.documentid
        join tblemployee_academicsdetails ea on ea.id = educationid
    where ea.employeeid =    P_EmployeeId 
    union ALl
    SELECT
    d.code AS Code,
    bd.filepath as FilePath
    FROM tbl_previous_company_documents  bd
        join tbl_documents  d on d.id = bd.documentid
        join tblemployee_previousemployerdetails cc on cc.id = bd.previous_company_id 
    where EmployeeID =    P_EmployeeId and Is_current_company = 1 
      union ALl 
    SELECT
    d.code AS Code,
    bd.filepath as FilePath
    FROM tbl_previous_company_documents  bd
        join tbl_documents  d on d.id = bd.documentid
        join tblemployee_experiencedetails cc on cc.id = bd.previous_company_id  
    where EmployeeID =    P_EmployeeId and Is_current_company = 0;




END PROC_GET_EMPLOYEE_ALL_DOCUMENT;