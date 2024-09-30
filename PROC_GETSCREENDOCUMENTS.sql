create or replace PROCEDURE           "PROC_GETSCREENDOCUMENTS" 
(
 sScreenName IN VARCHAR,
 iReferenceId IN INT DEFAULT 0,
 iEmployeeId in int,
 C_Documents out SYS_REFCURSOR
)
AS 
BEGIN
IF sScreenName='Basic_Document' THEN
OPEN C_Documents FOR
    Select d.Id As DocumentId,
           d.code,
           d.Attribute1 AS Required,
           d.description,
           d.screen AS ScreenName,
           d.allow_format as AllowFormat,
           f.filename,
           f.filePath,
           f.id ReferenceId
    from tbl_documents d 
    OUTER APPLY (Select * from tbl_basic_Documents f where f.employee_id  =iEmployeeId and d.id=f.DocumentId ) f
    Where d.Screen=sScreenName 
    Order by d.Id;

ELSIF sScreenName='Education_Document' THEN
OPEN C_Documents FOR
    Select Max(d.Id) As DocumentId,
           d.code,
            d.Attribute1 AS Required,
           d.description,
           d.screen AS ScreenName,
           d.allow_format as AllowFormat,
           max(f.filename) filename,
           max(f.filePath) filePath,
           f.id ReferenceId
    from tbl_documents d 
    OUTER APPLY (Select * from tblemployee_academicsdetails e where e.EmployeeId  =iEmployeeId AND e.id=iReferenceId and nvl(e.isdeleted,0)=0) e
    OUTER APPLY (Select * from tbl_education_documents f where f.documentId  = d.id AND f.educationId=e.Id and f.educationId=iReferenceId) f
    Where  d.Screen=sScreenName
    
    GROUP BY
    d.code,
     d.Attribute1,
    d.description,
    d.screen ,
    d.allow_format,
    f.id;

ELSIF sScreenName='Previous_Employer_Document' THEN
OPEN C_Documents FOR
    Select Max(d.Id) As DocumentId,
           d.code,
            d.Attribute1 AS Required,
           d.description,
           d.screen AS ScreenName,
           d.allow_format as AllowFormat,
           max(f.filename) filename,
           max(f.filePath) filePath,
           f.id ReferenceId
    from tbl_documents d 
    OUTER APPLY (Select * from tblemployee_experiencedetails e where e.EmployeeId  =iEmployeeId AND e.id=iReferenceId and nvl(e.isdeleted,0)=0) e
    OUTER APPLY (Select * from tbl_previous_company_documents f where f.documentId  = d.id AND f.previous_company_id=e.Id and f.previous_company_id=iReferenceId and nvl(f.is_current_company,0)=0) f 
    Where  d.Screen=sScreenName
    GROUP BY
    d.code,
     d.Attribute1,
    d.description,
    d.screen ,
    d.allow_format,
    f.id;

ELSIF sScreenName='Present_Employer_Document' THEN
OPEN C_Documents FOR
    Select Max(d.Id) As DocumentId,
           d.code,
          d.Attribute1 AS Required,
           d.description,
           d.screen AS ScreenName,
           d.allow_format as AllowFormat,
           max(f.filename) filename,
           max(f.filePath) filePath,
           f.id ReferenceId
    from tbl_documents d 
    OUTER APPLY (Select * from tblemployee_previousemployerdetails e where e.EmployeeId  =iEmployeeId AND e.id=iReferenceId and nvl(e.isdeleted,0)=0) e
    OUTER APPLY (Select * from tbl_previous_company_documents f where f.documentId  = d.id and f.previous_company_id=e.Id and nvl(f.is_current_company,0)=1) f 
    Where  d.Screen=sScreenName
    GROUP BY 
    d.code,
     d.Attribute1,
    d.description,
    d.screen ,
    d.allow_format,
    f.id;

ELSIF sScreenName='General_Document' THEN
OPEN C_Documents FOR
    Select Max(d.Id) As DocumentId,
           d.code,
            d.Attribute1 AS Required,
           d.description,
           d.screen AS ScreenName,
           d.allow_format as AllowFormat,
           max(f.filename) filename,
           max(f.filePath) filePath,
           f.id ReferenceId
    from tbl_documents d 
    OUTER APPLY (Select * from tblemployee_generalinformation e where e.EmployeeId  =iEmployeeId  and nvl(e.isdeleted,0)=0) e
    OUTER APPLY (Select * from tbl_general_documents f where f.documentId  = d.id and f.employee_id= iEmployeeId) f    
    Where  d.Screen=sScreenName
    GROUP BY 
    d.code,
     d.Attribute1,
    d.description,
    d.screen ,
    d.allow_format,
    f.id;
ELSIF sScreenName='Bank_Document' THEN
OPEN C_Documents FOR
    Select Max(d.Id) As DocumentId,
           d.code,
            d.Attribute1 AS Required,
           d.description,
           d.screen AS ScreenName,
           d.allow_format as AllowFormat,
           max(f.filename) filename,
           max(f.filePath) filePath,
           f.id ReferenceId
    from tbl_documents d 
    OUTER APPLY (Select * from tblemployee_bank_details e where e.EmployeeId  =iEmployeeId  and nvl(e.isdeleted,0)=0) e
    OUTER APPLY (Select * from TBL_BANK_DOCUMENTS f where f.documentId  = d.id and f.employee_id= iEmployeeId) f    
    Where  d.Screen=sScreenName
    GROUP BY 
    d.code,
     d.Attribute1,
    d.description,
    d.screen ,
    d.allow_format,
    f.id;
END IF;
END PROC_GetScreenDocuments;