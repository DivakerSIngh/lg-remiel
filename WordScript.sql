create or replace PROCEDURE           "PROC_GET_EMPLOYEEDETAILS_FOR_WORD" 
(
 P_EmployeeId IN INT DEFAULT 0,
 C_Details out SYS_REFCURSOR,
 C_Dependent out SYS_REFCURSOR,
 C_mediclaim out SYS_REFCURSOR,
 C_education out SYS_REFCURSOR,
 C_experience out SYS_REFCURSOR,
 C_currentcopany out SYS_REFCURSOR,
 C_generalinformation out SYS_REFCURSOR,
 C_reference out SYS_REFCURSOR,
 C_declaration out SYS_REFCURSOR,
 C_pledge out SYS_REFCURSOR,
 C_bank out SYS_REFCURSOR,
 C_nominee out SYS_REFCURSOR
)
AS 
BEGIN

 OPEN C_Details FOR
    SELECT 
        te.id,
        te.fullname,
        te.dob,
        te.age,
        te.placeofbirth,
        te.gender,
        te.religion,
        te.nationality,
        te.height,
        te.weight,
        te.bloodgroup,
        te.martialstatus,
        te.marriageanniversary,
        te.ageofboychildren,
        te.ageofgirlchildren,
        te.languagespeak,
        te.languageread,
        te.languagewrite,
        te.isdeleted,
        te.createddate,
        te.modifieddate,
        P_ENCRYPT_SYN.DECRYPT_SSN(te.emailid)as emailid,
        P_ENCRYPT_SYN.DECRYPT_SSN(te.mobilenumber) as mobilenumber,
        te.jobid,
        P_ENCRYPT_SYN.DECRYPT_SSN(te.pan) as pan,
        P_ENCRYPT_SYN.DECRYPT_SSN(te.aadhaar) as aadhaar,
        te.isreadtc,
        te.firstname,
        te.meddlename,
        te.lastname,
        te.isfresher,
        te.image_url,
        te.attribute1,
        te.attribute2,
        te.attribute3,
        te.attribute4,
        te.attribute5,
        te.attribute6,
        te.attribute7,
        te.attribute8,
        te.attribute9,
        te.attribute10,
        j.JobTitle as Positionapplied,
        add1.Address as PresentAddress, 
        add1.Pincode as PresentAddressPin, 
        add1.Telephone as PresentAddressTelephone, 
        add2.Address as PermanentAddress, 
        add2.Pincode as PermanentAddressPin, 
        add2.Telephone as PermanentAddressTelephone,
        md.value as EmployeeGender,
        md2.value as Martialstatusvalue,
        CONTACTPERSONNAME,
        RELATIONSHIP,
        PHONENUMBER,
        te.ADDRESS,
        te.IMAGE_URL as ImageUrl
    FROM tblEmployee te
        left JOIN tblEmployee_Address add1 ON add1.EmployeeId = te.Id and add1.Ispresentaddress = 1 
        left JOIN tblEmployee_Address add2 ON add2.EmployeeId = te.Id and add2.Ispresentaddress = 0
        left join tblmastardata md on te.gender = md.id
        left join tblmastardata md2 on te.Martialstatus = md2.id 
        join tbljobs j on j.id = te.jobId
    WHERE nvl(te.isdeleted,0)=0 
        and te.Id = P_EmployeeId;

    OPEN C_Dependent FOR
    SELECT 
        ROW_NUMBER() OVER ( ORDER BY tedd.id desc) as id,
        fullname,
        age,
        md.value as RelationValue,
        tedd.Occupation,
        tedd.attribute1,
        tedd.attribute2,
        tedd.attribute9
    FROM tblEmployee_DependentsDetails tedd 
        join tblmastardata md on tedd.Relationship = md.id
    WHERE tedd.isdeleted = 0
        AND tedd.EmployeeId = P_EmployeeId;

    OPEN C_mediclaim FOR
    SELECT 
        ROW_NUMBER() OVER ( ORDER BY tedd.id desc) as id,
        name,
        dob,
        md2.value as RelationValue,
        md.value as GenderValue
    FROM tbl_employee_mediclaim_declaration tedd 
        join tblmastardata md on tedd.gender = md.id
        join tblmastardata md2 on tedd.relation = md2.id
    WHERE tedd.Employee_Id = P_EmployeeId;  

    OPEN C_education FOR
    SELECT 
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        academicqualification,
        fromdate,
        todate,
        institution,
        stream,
        marks
    FROM tblemployee_academicsdetails
    WHERE EmployeeId= P_EmployeeId;

    OPEN C_experience FOR    
    SELECT
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        companyname,
        department,
        finaldesignation,
        initialpackage,
        currentpackage,
        fromdate,
        todate
    FROM tblemployee_experiencedetails
    WHERE EmployeeId= P_EmployeeId;

    OPEN C_currentcopany FOR
    SELECT
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        employername as "Employername",
        employeraddress as "Employeraddress",
        telephone as "Telephone",
        fax as "Fax",
        doj as "Doj",
        initialdesignation as "Initialdesignation",
        presentdesignation as "Presentdesignation",
        effectivedate as "Effectivedate",
        reasonforchange as "Reasonforchange"
    FROM tblemployee_previousemployerdetails
    WHERE EmployeeId= P_EmployeeId;

    OPEN C_generalinformation FOR
    SELECT
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        noticeperiod,
        possibledoj,
        P_ENCRYPT_SYN.DECRYPT_SSN(passport) as passport,
        hobbies,
        isonanycontract,
        contractdetail,
        isengagedinanybusiness,
        businessdetail,
        isappliedinpast,
        applieddetail,
        isanyrelative,
        relativedetail,
        anychronicillness,
        illnessdetail,
        anysurgery,
        surgerydetail
    FROM tblemployee_generalinformation
    WHERE EmployeeId= P_EmployeeId;

    OPEN C_reference FOR
    SELECT
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        particulars,
        beforeemployment,
        afteremployment
    FROM tblemployee_referencedetails
    WHERE EmployeeId= P_EmployeeId;

    OPEN C_declaration FOR 
    SELECT
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        declarationdate,
        place,
        signature
    FROM tblemployee_declaration
    WHERE EmployeeId= P_EmployeeId;

    OPEN C_pledge FOR 
    SELECT
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        NVL(remark1,'') as remark1,
        NVL(remark2,'') as remark2,
        NVL(remark3,'') as remark3,
        NVL(remark4,'') as remark4
    FROM tbl_pledge_of_action
    WHERE employee_id= P_EmployeeId;
    
    OPEN C_bank FOR 
    SELECT
        ROW_NUMBER() OVER ( ORDER BY id desc) as id,
        P_ENCRYPT_SYN.DECRYPT_SSN(account_number) As AccountNumber,
        bank_name as BankName,
        ifsc_code as IfscCode
    FROM tblemployee_bank_details
    WHERE employeeid = P_EmployeeId;
    
        OPEN C_nominee FOR--changes
    select 
     ROW_NUMBER() OVER ( ORDER BY te.id desc) as id,
     te.Membername,
     md.value as AgeValue,
     rd.value as RelationshipValue,
     smd.value as StateValue,
     te.Share_Percentage as SharePercentage,
     City,
     Pincode,
     Telephone,
     PermanentAddress,
     Minor_Nominee as MinorNominee
    from TBL_NOMINEE_DETAILS te
         join tblmastardata md on te.age = md.id 
         join tblmastardata rd on te.relationship = rd.id 
         join tblmastardata smd on te.STATE = smd.id
    WHERE te.EMPLOYEEID = P_EmployeeId;

END PROC_Get_EmployeeDetails_For_Word;