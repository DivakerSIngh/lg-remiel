create or replace PROCEDURE           "PROC_GET_EMPLOYEEDETAILS_REPORT" 
(
 EmpJobId IN number DEFAULT 0,
 SearchText IN  NVARCHAR2 DEFAULT '',
  P_FromDate IN NVarchar2 DEFAULT '',
 P_ToDate IN NVarchar2 DEFAULT '',
 P_Status IN NVARCHAR2 DEFAULT ' ',
 C_Details out SYS_REFCURSOR
)
AS 
BEGIN
  -- Truncate the target table
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TBLEMPLYOEE_REPORT';

  -- Insert employee details into the target table
    -- Insert employee details into the target table
  INSERT INTO "LGROBDB"."TBLEMPLYOEE_REPORT" 
   (
	"EMPLOYEEID" , 
    "FULLNAME" ,
    "PAN" ,
    "AADHAAR" ,
	"PRESENTADDRESS" ,
    "PRESENTCITY",
    "PRESENTSTATE",
    "PRESENTADDRESSPIN" ,
    "PRESENTADDRESSTELEPHONE" ,
    "PERMANENTADDRESS" ,
    "PERMANENTCITY",
    "PERMANENTSTATE",
    "PERMANENTADDRESSPIN" ,
    "PERMANENTADDRESSTELEPHONE" ,
	"DateOfBirth" , 
	"AGE" , 
	"PLACEOFBIRTH" , 
	"GENDER" , 
	"RELIGION" , 
	"NATIONALITY" , 
	"HEIGHT" , 
	"WEIGHT" , 
	"BLOODGROUP" , 
	"MARTIALSTATUS" , 
	"MARRIAGEANNIVERSARY" , 
	"AGEOFBOYCHILDREN" , 
	"AGEOFGIRLCHILDREN", 
	"LANGUAGESPEAK" , 
	"LANGUAGEREAD" , 
	"LANGUAGEWRITE",
    "EMAIL",
    "PHOTOGRAPHSSTATUS"
    )
    SELECT 
        emp.ID,
        emp.FULLNAME as EmployeeName,
        P_ENCRYPT_SYN.DECRYPT_SSN(emp.PAN),
        P_ENCRYPT_SYN.DECRYPT_SSN(emp.AADHAAR),
        add1.Address as PresentAddress,
       -- pcity.CITY as PresentCity,
       add1.city as PresentCity,
        pstate.VALUE as PresentState,
        add1.Pincode as PresentAddressPin, 
        add1.Telephone as PresentAddressTelephone, 
        add2.Address as PermanentAddress,
       -- C.CITY as PresentCity,
        add2.city as PermanentCity,
        S.VALUE as PresentState,
        add2.Pincode as PermanentAddressPin, 
        add2.Telephone as PermanentAddressTelephone,
        emp.DOB as DateOfBirth, 
        fn_MasterValues('Age',emp.AGE) as AGE,
        emp.PLACEOFBIRTH,
        fn_MasterValues('Gender',emp.GENDER) as Gender,
        emp.RELIGION,
        emp.NATIONALITY,
        emp.HEIGHT,
        emp.WEIGHT,
        emp.BLOODGROUP,
        fn_MasterValues('MartialStatus',emp.MartialStatus) as MartialStatus,
        emp.MARRIAGEANNIVERSARY as MarriedDate,
        fn_MasterValues('Age',emp.AGEOFBOYCHILDREN) as AGEOFBOYCHILDREN,
        fn_MasterValues('Age',emp.AGEOFGIRLCHILDREN) as AGEOFGIRLCHILDREN,
        emp.LANGUAGESPEAK,
        emp.LANGUAGEREAD,
        emp.LANGUAGEWRITE,
        P_ENCRYPT_SYN.DECRYPT_SSN(emp.emailid),
        CASE WHEN image_url <> NULL THEN 'True' else 'False' end 
    FROM tblEmployee emp
        left JOIN tblEmployee_Address add1 
            join tblmastardata pstate on pstate.ID = add1.state
            --join tblcitymaster pcity on pcity.ID =  add1.city
        ON add1.EmployeeId = emp.Id and add1.Ispresentaddress = 1 
        left JOIN tblEmployee_Address add2 
            join tblmastardata s on s.ID = add2.state
           -- join tblcitymaster c on c.ID =  add2.city
        ON add2.EmployeeId = emp.Id and add2.Ispresentaddress = 0
        join tbljobs j on j.id = emp.jobId 
        join tblemployeestatus st on emp.id = st.employeeid and st.isactive=1
   WHERE ((j.id = EmpJobId OR NVL(EmpJobId,0)=0) and st.Isactive =1) 
     AND( lower(emp.Fullname) like '%'|| lower(NVL(SearchText,'')) ||'%'
     OR lower(emp.EMAILID) like '%'|| lower(NVL(SearchText,'')) ||'%'
     OR lower(emp.Mobilenumber) like '%'|| lower(NVL(SearchText,'')) ||'%'
     OR lower(j.Jobtitle) like '%'|| lower(NVL(SearchText,'')) ||'%'
     OR lower(st.Employee_Status) like '%'|| lower(NVL(SearchText,'')) ||'%')
     and TRUNC(emp.createddate) >= case when NVL(P_FromDate,' ') = ' ' then TRUNC(emp.createddate) else TO_DATE(P_FromDate, 'DD-Mon-YY')  end
     and TRUNC(emp.createddate) <= case when NVL(P_ToDate,' ') = ' ' then TRUNC(emp.createddate) else TO_DATE(P_ToDate, 'DD-Mon-YY')  end
     and st.EMPLOYEE_STATUS = case when NVL(P_Status,' ') != ' ' then NVL(P_Status,' ') else cast(st.EMPLOYEE_STATUS as nvarchar2(20)) end;

  -- Update additional columns in the target table
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.FATHER = (
    SELECT tedd.fullname
    FROM tblEmployee_DependentsDetails tedd 
    JOIN tblmastardata md ON tedd.Relationship = md.id AND md.value = 'Father'  
    WHERE tedd.EmployeeId = RE.EMPLOYEEID AND tedd.isdeleted = 0
  );

  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.MOTHER = (
    SELECT tedd.fullname
    FROM tblEmployee_DependentsDetails tedd 
    JOIN tblmastardata md ON tedd.Relationship = md.id AND md.value = 'Mother'  
    WHERE tedd.EmployeeId = RE.EMPLOYEEID AND tedd.isdeleted = 0
  );

  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.SPOUSE = (
    SELECT tedd.fullname
    FROM tblEmployee_DependentsDetails tedd 
    JOIN tblmastardata md ON tedd.Relationship = md.id AND md.value = 'Spouse'  
    WHERE tedd.EmployeeId = RE.EMPLOYEEID AND tedd.isdeleted = 0
  );

  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.CURRENTCOMPANY = (
    SELECT tedd.employername
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );

  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.CURRENTCOMPANYDESIGNATION = (
    SELECT tedd.presentdesignation
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );

  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.CURRENTCOMPANYFROM = (
    SELECT tedd.doj
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );

  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.CURRENTCOMPANYTO = (
    SELECT tedd.effectivedate
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );----
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."employeraddress" = (
    SELECT tedd.employeraddress
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."telephone" = (
    SELECT tedd.telephone
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."fax" = (
    SELECT tedd.fax
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."initialdesignation" = (
    SELECT tedd.initialdesignation
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."reasonforchange" = (
    SELECT tedd.reasonforchange
    FROM tblemployee_previousemployerdetails tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );
  ----
  
      UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.bank_name = (
    SELECT tedd.bank_name
    FROM tblemployee_bank_details tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
  );
  
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.account_number = (
    SELECT tedd.account_number
    FROM tblemployee_bank_details tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
        AND tedd.bank_name <> 'Other'
  );
  

    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE.ifsc_code = (
    SELECT tedd.ifsc_code
    FROM tblemployee_bank_details tedd 
    WHERE tedd.EmployeeId = RE.EMPLOYEEID
        AND tedd.bank_name <> 'Other'
  );
 ---------------------------------------------------------------------------------------------------------------------- 
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Basic" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'A'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Basic" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'A'
  );
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_HRA_CLA" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'B'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_HRA_CLA" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'B'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Conveyance" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'C'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Conveyance" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'C'
  );---------------------
        UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_SpecialAllowance" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'D'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_SpecialAllowance" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'D'
  );---------------------------
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_LTA" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'E'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_LTA" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'E'
  );------------------------
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Medical" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'F'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Medical" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'F'
  );----------------------
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Bonus" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'G'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Bonus" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'G'
  );----------------------------
               UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_PF" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'H'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_PF" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'H'
  );---------------------------
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Gratuity" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'I'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Gratuity" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'I'
  ); -----------
               UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Superannuation" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'J'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Superannuation" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'J'
  ); ---------
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Others" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'K'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Others" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'K'
  );------------
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Monthly_Total" = (
    select monthly
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'L'
  );
  UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."Yearly_Total" = (
    select annual
    from tblemployee_ctccomponentvalue cv
        join tblctccomponent cd on cv.compoentid = cd.id  
    WHERE cv.employeeid = RE.EMPLOYEEID
        AND cd.extractname = 'L'
  );
  ----------------------------------------------------
    UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."ctcexpected" = (
    select ctcexpected
    from tblemplyoee_ctcadditionaldetails cv
    WHERE cv.employeeid = RE.EMPLOYEEID
  );
      UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."presentjobresponsisblities" = (
    select presentjobresponsisblities
    from tblemplyoee_ctcadditionaldetails cv
    WHERE cv.employeeid = RE.EMPLOYEEID
  );
      UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."positionstructure" = (
    select positionstructure
    from tblemplyoee_ctcadditionaldetails cv
    WHERE cv.employeeid = RE.EMPLOYEEID
  );
      UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."contributioninforpastemployer" = (
    select contributioninforpastemployer
    from tblemplyoee_ctcadditionaldetails cv
    WHERE cv.employeeid = RE.EMPLOYEEID
  );
        UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."membershipofprofessionalorganisation" = (
    select membershipofprofessionalorganisation
    from tblemplyoee_ctcadditionaldetails cv
    WHERE cv.employeeid = RE.EMPLOYEEID
  );
        UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
  SET RE."trainingprogrammeattended" = (
    select trainingprogrammeattended
    from tblemplyoee_ctcadditionaldetails cv
    WHERE cv.employeeid = RE.EMPLOYEEID
  );
  




  -- Declare variables for cursor and employee ID
  DECLARE
    CURSOR c_employee IS
      SELECT DISTINCT EMPLOYEEID
      FROM TBLEMPLYOEE_REPORT;

    v_employee_id TBLEMPLYOEE_REPORT.EMPLOYEEID%TYPE;
  BEGIN
    OPEN c_employee;

    LOOP
      FETCH c_employee INTO v_employee_id;
      EXIT WHEN c_employee%NOTFOUND;

      -- Update columns for boy children
      DECLARE
        v_name tblEmployee_DependentsDetails.fullname%TYPE;
        counter NUMBER := 1;
      BEGIN
        FOR rec IN (
          SELECT tedd.fullname
          FROM tblEmployee_DependentsDetails tedd 
          JOIN tblmastardata md ON tedd.Relationship = md.id AND md.value = 'BoyChild'  
          WHERE tedd.EmployeeId = v_employee_id AND tedd.isdeleted = 0
        )
        LOOP
          v_name := rec.fullname;
          UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
          SET 
            RE.BOY1 = CASE WHEN counter = 1 THEN v_name ELSE RE.BOY1 END,
            RE.BOY2 = CASE WHEN counter = 2 THEN v_name ELSE RE.BOY2 END,
            RE.BOY3 = CASE WHEN counter = 3 THEN v_name ELSE RE.BOY3 END,
            RE.BOY4 = CASE WHEN counter = 4 THEN v_name ELSE RE.BOY4 END,
            RE.BOY5 = CASE WHEN counter = 5 THEN v_name ELSE RE.BOY5 END
          WHERE RE.EmployeeId = v_employee_id;
          counter := counter + 1;
        END LOOP;
      END;

      -- Update columns for girl children
      DECLARE
        v_name tblEmployee_DependentsDetails.fullname%TYPE;
        counter NUMBER := 1;
      BEGIN
        FOR rec IN (
          SELECT tedd.fullname
          FROM tblEmployee_DependentsDetails tedd 
          JOIN tblmastardata md ON tedd.Relationship = md.id AND md.value = 'GirlChild'  
          WHERE tedd.EmployeeId = v_employee_id AND tedd.isdeleted = 0
        )
        LOOP
          v_name := rec.fullname;
          UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
          SET 
            RE.GIRL1 = CASE WHEN counter = 1 THEN v_name ELSE RE.GIRL1 END,
            RE.GIRL2 = CASE WHEN counter = 2 THEN v_name ELSE RE.GIRL2 END,
            RE.GIRL3 = CASE WHEN counter = 3 THEN v_name ELSE RE.GIRL3 END,
            RE.GIRL4 = CASE WHEN counter = 4 THEN v_name ELSE RE.GIRL4 END,
            RE.GIRL5 = CASE WHEN counter = 5 THEN v_name ELSE RE.GIRL5 END
          WHERE RE.EmployeeId = v_employee_id;
          counter := counter + 1;
        END LOOP;
      END;

     -- Update columns for academic qualifications
      DECLARE
          v_name tblemployee_academicsdetails.academicqualification%TYPE;
          v_date tblemployee_academicsdetails.todate%TYPE;
          v_fromdate tblemployee_academicsdetails.fromdate%TYPE;
          v_institution tblemployee_academicsdetails.institution%TYPE;
          v_subject tblemployee_academicsdetails.stream%TYPE;
          counter NUMBER := 1;
      BEGIN
        FOR rec IN (
          SELECT 
            tedd.academicqualification, 
            tedd.todate, 
            tedd.fromdate,
            tedd.institution, 
            tedd.stream 
          FROM tblemployee_academicsdetails tedd 
          WHERE tedd.EmployeeId = v_employee_id AND tedd.isdeleted = 0
        )
        LOOP
          v_name := rec.academicqualification;
          v_date := rec.todate;
          v_fromdate := rec.fromdate;
          v_institution := rec.institution;
          v_subject := rec.stream;

          UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
          SET 
            RE.ACADEMIC1DEGREENAME = CASE WHEN counter = 1 THEN v_name ELSE RE.ACADEMIC1DEGREENAME END,
            RE.ACADEMIC1_FROM = CASE WHEN counter = 1 THEN v_fromdate ELSE RE.ACADEMIC1_FROM END,
            RE.ACADEMIC1_TO = CASE WHEN counter = 1 THEN v_date ELSE RE.ACADEMIC1_TO END,
            RE.ACADEMIC1_PASSINGYEAR = CASE WHEN counter = 1 THEN v_date ELSE RE.ACADEMIC1_PASSINGYEAR END,
            RE.ACADEMIC1INSTITUTIONNAME = CASE WHEN counter = 1 THEN v_institution ELSE RE.ACADEMIC1INSTITUTIONNAME END,
            RE.ACADEMIC1SUBJECT = CASE WHEN counter = 1 THEN v_subject ELSE RE.ACADEMIC1SUBJECT END,
            RE.ACADEMIC2DEGREENAME = CASE WHEN counter = 2 THEN v_name ELSE RE.ACADEMIC2DEGREENAME END,
            RE.ACADEMIC2_FROM = CASE WHEN counter = 2 THEN v_fromdate ELSE RE.ACADEMIC2_FROM END,
            RE.ACADEMIC2_TO = CASE WHEN counter = 2 THEN v_date ELSE RE.ACADEMIC2_TO END,
            RE.ACADEMIC2_PASSINGYEAR = CASE WHEN counter = 2 THEN v_date ELSE RE.ACADEMIC2_PASSINGYEAR END,
            RE.ACADEMIC2INSTITUTIONNAME = CASE WHEN counter = 2 THEN v_institution ELSE RE.ACADEMIC2INSTITUTIONNAME END,
            RE.ACADEMIC2SUBJECT = CASE WHEN counter = 2 THEN v_subject ELSE RE.ACADEMIC2SUBJECT END,
            RE.ACADEMIC3DEGREENAME = CASE WHEN counter = 3 THEN v_name ELSE RE.ACADEMIC3DEGREENAME END,
            RE.ACADEMIC3_FROM = CASE WHEN counter = 3 THEN v_fromdate ELSE RE.ACADEMIC3_FROM END,
            RE.ACADEMIC3_TO = CASE WHEN counter = 3 THEN v_date ELSE RE.ACADEMIC3_TO END,
            RE.ACADEMIC3_PASSINGYEAR = CASE WHEN counter = 3 THEN v_date ELSE RE.ACADEMIC3_PASSINGYEAR END,
            RE.ACADEMIC3INSTITUTIONNAME = CASE WHEN counter = 3 THEN v_institution ELSE RE.ACADEMIC3INSTITUTIONNAME END,
            RE.ACADEMIC3SUBJECT = CASE WHEN counter = 3 THEN v_subject ELSE RE.ACADEMIC3SUBJECT END,
            RE.ACADEMIC4DEGREENAME = CASE WHEN counter = 4 THEN v_name ELSE RE.ACADEMIC4DEGREENAME END,
            RE.ACADEMIC4_FROM = CASE WHEN counter = 4 THEN v_fromdate ELSE RE.ACADEMIC4_FROM END,
            RE.ACADEMIC4_TO = CASE WHEN counter = 4 THEN v_date ELSE RE.ACADEMIC4_TO END,
            RE.ACADEMIC4_PASSINGYEAR = CASE WHEN counter = 4 THEN v_date ELSE RE.ACADEMIC4_PASSINGYEAR END,
            RE.ACADEMIC4INSTITUTIONNAME = CASE WHEN counter = 4 THEN v_institution ELSE RE.ACADEMIC4INSTITUTIONNAME END,
            RE.ACADEMIC4SUBJECT = CASE WHEN counter = 4 THEN v_subject ELSE RE.ACADEMIC4SUBJECT END,
            RE.ACADEMIC5DEGREENAME = CASE WHEN counter = 5 THEN v_name ELSE RE.ACADEMIC5DEGREENAME END,
            RE.ACADEMIC5_FROM = CASE WHEN counter = 5 THEN v_fromdate ELSE RE.ACADEMIC5_FROM END,
            RE.ACADEMIC5_TO = CASE WHEN counter = 5 THEN v_date ELSE RE.ACADEMIC5_TO END,
            RE.ACADEMIC5_PASSINGYEAR = CASE WHEN counter = 5 THEN v_date ELSE RE.ACADEMIC5_PASSINGYEAR END,
            RE.ACADEMIC5INSTITUTIONNAME = CASE WHEN counter = 5 THEN v_institution ELSE RE.ACADEMIC5INSTITUTIONNAME END,
            RE.ACADEMIC5SUBJECT = CASE WHEN counter = 5 THEN v_subject ELSE RE.ACADEMIC5SUBJECT END
          WHERE RE.EmployeeId = v_employee_id;

          counter := counter + 1;
        END LOOP;
      END;

      -- Update columns for previous company details
          -- Update columns for previous company details
      DECLARE
        v_name tblemployee_experiencedetails.companyname%TYPE;
        v_fromdate tblemployee_experiencedetails.fromdate%TYPE;
        v_todate tblemployee_experiencedetails.todate%TYPE;
        v_department tblemployee_experiencedetails.department%TYPE;
        v_responsibilities nvarchar2(250);
        v_ctc nvarchar2(130);
        v_experience number(10,5);


        counter NUMBER := 1;
      BEGIN
        FOR rec IN (
          SELECT 
            tedd.companyname, 
            tedd.fromdate,
            tedd.todate, 
            tedd.department,
            tedd.responsibilities as responsibilities,
            cast(tedd.currentpackage as nvarchar2(130)) as currentpackage,
            EXTRACT(YEAR FROM tedd.todate) - EXTRACT(YEAR FROM  tedd.fromdate) as experience 
          FROM tblemployee_experiencedetails tedd 
          WHERE tedd.EmployeeId = v_employee_id AND tedd.isdeleted = 0
        )
        LOOP
          v_name := rec.companyname;
          v_fromdate := rec.fromdate;
          v_todate := rec.todate;
          v_department := rec.department;
          v_responsibilities := rec.responsibilities;
          v_ctc := rec.currentpackage;
          v_experience := rec.experience;
          UPDATE "LGROBDB"."TBLEMPLYOEE_REPORT" RE
          SET 
            RE.PREVIOUSCOMPANY1 = CASE WHEN counter = 1 THEN v_name ELSE RE.PREVIOUSCOMPANY1 END,
            RE.PREVIOUSCOMPANY1_FROM = CASE WHEN counter = 1 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY1_FROM END,
            RE.PREVIOUSCOMPANY1_TO = CASE WHEN counter = 1 THEN v_todate ELSE RE.PREVIOUSCOMPANY1_TO END,
            RE.PREVIOUSCOMPANY1DEPTNAME = CASE WHEN counter = 1 THEN v_department ELSE RE.PREVIOUSCOMPANY1DEPTNAME END,
            RE.PREVIOUSCOMPANY1RESPONSIBILITIES = CASE WHEN counter = 1 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY1RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY1CTC = CASE WHEN counter = 1 THEN v_ctc ELSE RE.PREVIOUSCOMPANY1CTC END,
            RE.PREVIOUSCOMPANY1EXPERIENCE = CASE WHEN counter = 1 THEN v_experience ELSE RE.PREVIOUSCOMPANY1EXPERIENCE END,

            RE.PREVIOUSCOMPANY2 = CASE WHEN counter = 2 THEN v_name ELSE RE.PREVIOUSCOMPANY2 END,
            RE.PREVIOUSCOMPANY2_FROM = CASE WHEN counter = 2 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY2_FROM END,
            RE.PREVIOUSCOMPANY2_TO = CASE WHEN counter = 2 THEN v_todate ELSE RE.PREVIOUSCOMPANY2_TO END,
            RE.PREVIOUSCOMPANY2DEPTNAME = CASE WHEN counter = 2 THEN v_department ELSE RE.PREVIOUSCOMPANY2DEPTNAME END,
            RE.PREVIOUSCOMPANY2RESPONSIBILITIES = CASE WHEN counter = 2 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY2RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY2CTC = CASE WHEN counter = 2 THEN v_ctc ELSE RE.PREVIOUSCOMPANY2CTC END,
            RE.PREVIOUSCOMPANY2EXPERIENCE = CASE WHEN counter = 2 THEN v_experience ELSE RE.PREVIOUSCOMPANY2EXPERIENCE END,

            RE.PREVIOUSCOMPANY3 = CASE WHEN counter = 3 THEN v_name ELSE RE.PREVIOUSCOMPANY3 END,
            RE.PREVIOUSCOMPANY3_FROM = CASE WHEN counter = 3 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY3_FROM END,
            RE.PREVIOUSCOMPANY3_TO = CASE WHEN counter = 3 THEN v_todate ELSE RE.PREVIOUSCOMPANY3_TO END,
            RE.PREVIOUSCOMPANY3DEPTNAME = CASE WHEN counter = 3 THEN v_department ELSE RE.PREVIOUSCOMPANY3DEPTNAME END,
            RE.PREVIOUSCOMPANY3RESPONSIBILITIES = CASE WHEN counter = 3 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY3RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY3CTC = CASE WHEN counter = 3 THEN v_ctc ELSE RE.PREVIOUSCOMPANY3CTC END,
            RE.PREVIOUSCOMPANY3EXPERIENCE = CASE WHEN counter = 3 THEN v_experience ELSE RE.PREVIOUSCOMPANY3EXPERIENCE END,

            RE.PREVIOUSCOMPANY4 = CASE WHEN counter = 4 THEN v_name ELSE RE.PREVIOUSCOMPANY4 END,
            RE.PREVIOUSCOMPANY4_FROM = CASE WHEN counter = 4 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY4_FROM END,
            RE.PREVIOUSCOMPANY4_TO = CASE WHEN counter = 4 THEN v_todate ELSE RE.PREVIOUSCOMPANY4_TO END,
            RE.PREVIOUSCOMPANY4DEPTNAME = CASE WHEN counter = 4 THEN v_department ELSE RE.PREVIOUSCOMPANY4DEPTNAME END,
            RE.PREVIOUSCOMPANY4RESPONSIBILITIES = CASE WHEN counter = 4 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY4RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY4CTC = CASE WHEN counter = 4 THEN v_ctc ELSE RE.PREVIOUSCOMPANY4CTC END,
            RE.PREVIOUSCOMPANY4EXPERIENCE = CASE WHEN counter = 4 THEN v_experience ELSE RE.PREVIOUSCOMPANY4EXPERIENCE END,

            RE.PREVIOUSCOMPANY5 = CASE WHEN counter = 5 THEN v_name ELSE RE.PREVIOUSCOMPANY5 END,
            RE.PREVIOUSCOMPANY5_FROM = CASE WHEN counter = 5 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY5_FROM END,
            RE.PREVIOUSCOMPANY5_TO = CASE WHEN counter = 5 THEN v_todate ELSE RE.PREVIOUSCOMPANY5_TO END,
            RE.PREVIOUSCOMPANY5DEPTNAME = CASE WHEN counter = 5 THEN v_department ELSE RE.PREVIOUSCOMPANY5DEPTNAME END,
            RE.PREVIOUSCOMPANY5RESPONSIBILITIES = CASE WHEN counter = 5 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY5RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY5CTC = CASE WHEN counter = 5 THEN v_ctc ELSE RE.PREVIOUSCOMPANY5CTC END,
            RE.PREVIOUSCOMPANY5EXPERIENCE = CASE WHEN counter = 5 THEN v_experience ELSE RE.PREVIOUSCOMPANY5EXPERIENCE END,

            RE.PREVIOUSCOMPANY6 = CASE WHEN counter = 6 THEN v_name ELSE RE.PREVIOUSCOMPANY6 END,
            RE.PREVIOUSCOMPANY6_FROM = CASE WHEN counter = 6 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY6_FROM END,
            RE.PREVIOUSCOMPANY6_TO = CASE WHEN counter = 6 THEN v_todate ELSE RE.PREVIOUSCOMPANY6_TO END,
            RE.PREVIOUSCOMPANY6DEPTNAME = CASE WHEN counter = 6 THEN v_department ELSE RE.PREVIOUSCOMPANY6DEPTNAME END,
            RE.PREVIOUSCOMPANY6RESPONSIBILITIES = CASE WHEN counter = 6 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY6RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY6CTC = CASE WHEN counter = 6 THEN v_ctc ELSE RE.PREVIOUSCOMPANY6CTC END,
            RE.PREVIOUSCOMPANY6EXPERIENCE = CASE WHEN counter = 6 THEN v_experience ELSE RE.PREVIOUSCOMPANY6EXPERIENCE END,

            RE.PREVIOUSCOMPANY7 = CASE WHEN counter = 7 THEN v_name ELSE RE.PREVIOUSCOMPANY7 END,
            RE.PREVIOUSCOMPANY7_FROM = CASE WHEN counter = 7 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY7_FROM END,
            RE.PREVIOUSCOMPANY7_TO = CASE WHEN counter = 7 THEN v_todate ELSE RE.PREVIOUSCOMPANY7_TO END,
            RE.PREVIOUSCOMPANY7DEPTNAME = CASE WHEN counter = 7 THEN v_department ELSE RE.PREVIOUSCOMPANY7DEPTNAME END,
            RE.PREVIOUSCOMPANY7RESPONSIBILITIES = CASE WHEN counter = 7 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY7RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY7CTC = CASE WHEN counter = 7 THEN v_ctc ELSE RE.PREVIOUSCOMPANY7CTC END,
            RE.PREVIOUSCOMPANY7EXPERIENCE = CASE WHEN counter = 7 THEN v_experience ELSE RE.PREVIOUSCOMPANY7EXPERIENCE END,

            RE.PREVIOUSCOMPANY8 = CASE WHEN counter = 8 THEN v_name ELSE RE.PREVIOUSCOMPANY8 END,
            RE.PREVIOUSCOMPANY8_FROM = CASE WHEN counter = 8 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY8_FROM END,
            RE.PREVIOUSCOMPANY8_TO = CASE WHEN counter = 8 THEN v_todate ELSE RE.PREVIOUSCOMPANY8_TO END,
            RE.PREVIOUSCOMPANY8DEPTNAME = CASE WHEN counter = 8 THEN v_department ELSE RE.PREVIOUSCOMPANY8DEPTNAME END,
            RE.PREVIOUSCOMPANY8RESPONSIBILITIES = CASE WHEN counter = 8 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY8RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY8CTC = CASE WHEN counter = 8 THEN v_ctc ELSE RE.PREVIOUSCOMPANY8CTC END,
            RE.PREVIOUSCOMPANY8EXPERIENCE = CASE WHEN counter = 8 THEN v_experience ELSE RE.PREVIOUSCOMPANY8EXPERIENCE END,

            RE.PREVIOUSCOMPANY9 = CASE WHEN counter = 9 THEN v_name ELSE RE.PREVIOUSCOMPANY9 END,
            RE.PREVIOUSCOMPANY9_FROM = CASE WHEN counter = 9 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY9_FROM END,
            RE.PREVIOUSCOMPANY9_TO = CASE WHEN counter = 9 THEN v_todate ELSE RE.PREVIOUSCOMPANY9_TO END,
            RE.PREVIOUSCOMPANY9DEPTNAME = CASE WHEN counter = 9 THEN v_department ELSE RE.PREVIOUSCOMPANY9DEPTNAME END,
            RE.PREVIOUSCOMPANY9RESPONSIBILITIES = CASE WHEN counter = 9 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY9RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY9CTC = CASE WHEN counter = 9 THEN v_ctc ELSE RE.PREVIOUSCOMPANY9CTC END,
            RE.PREVIOUSCOMPANY9EXPERIENCE = CASE WHEN counter = 9 THEN v_experience ELSE RE.PREVIOUSCOMPANY9EXPERIENCE END,

            RE.PREVIOUSCOMPANY10 = CASE WHEN counter = 10 THEN v_name ELSE RE.PREVIOUSCOMPANY10 END,
            RE.PREVIOUSCOMPANY10_FROM = CASE WHEN counter = 10 THEN v_fromdate ELSE RE.PREVIOUSCOMPANY10_FROM END,
            RE.PREVIOUSCOMPANY10_TO = CASE WHEN counter = 10 THEN v_todate ELSE RE.PREVIOUSCOMPANY10_TO END,
            RE.PREVIOUSCOMPANY10DEPTNAME = CASE WHEN counter = 10 THEN v_department ELSE RE.PREVIOUSCOMPANY10DEPTNAME END,
            RE.PREVIOUSCOMPANY10RESPONSIBILITIES = CASE WHEN counter = 10 THEN v_responsibilities ELSE RE.PREVIOUSCOMPANY10RESPONSIBILITIES END,
            RE.PREVIOUSCOMPANY10CTC = CASE WHEN counter = 10 THEN v_ctc ELSE RE.PREVIOUSCOMPANY10CTC END,
            RE.PREVIOUSCOMPANY10EXPERIENCE = CASE WHEN counter = 10 THEN v_experience ELSE RE.PREVIOUSCOMPANY10EXPERIENCE END


          WHERE RE.EmployeeId = v_employee_id;
          counter := counter + 1;
        END LOOP;
      END;


    END LOOP;
    CLOSE c_employee;
  END;
  -- Open the cursor for the result set
  OPEN C_Details FOR
            -- Open the cursor for the result set
  SELECT 

 	EMPLOYEEID AS "Employee Id" , 
	FULLNAME AS "Full Name" , 
	PAN AS "Pan", 
	AADHAAR  AS "Aadhaar", 
	PRESENTADDRESS AS "Present Address" ,
    PRESENTCITY as "Present City",
    PRESENTSTATE as "Present State",
	PRESENTADDRESSPIN AS " Pin" , 
	PRESENTADDRESSTELEPHONE AS " Telephone" , 
	PERMANENTADDRESS AS "Permanent Address" ,
    PERMANENTCITY  AS "Permanent City",
    PERMANENTSTATE  AS "Permanent State",
	PERMANENTADDRESSPIN AS "Pin ", 
	PERMANENTADDRESSTELEPHONE AS "Telephone " , 

	TRUNC("DateOfBirth") AS "Date Of Birth" , 
	AGE  AS "Age", 
	PLACEOFBIRTH AS "Birth Place", 
	GENDER AS "Gender", 
	RELIGION AS "Religion" , 
	NATIONALITY AS "Nationality", 
	HEIGHT AS "Height", 
	WEIGHT AS "Weight" , 
	BLOODGROUP AS "Blood Group" , 
	MARTIALSTATUS AS "Maritial Status" , 
	TRUNC(MARRIAGEANNIVERSARY) AS  "Marriage Anniversory", 
	AGEOFBOYCHILDREN AS "Age Of Boy Children" , 
	AGEOFGIRLCHILDREN  AS "Age Of Girl Children", 
	LANGUAGESPEAK  AS "Language Speak", 
	LANGUAGEREAD  AS "Language Read" , 
	LANGUAGEWRITE  AS "Language Write" , 
	FATHER  AS "Father", 
	MOTHER AS "Mother", 
	SPOUSE AS "Spouse" , 
	BOY1 AS "Son 1" , 
	BOY2 AS "Son 2", 
	BOY3 AS "Son 3", 
	BOY4 AS "Son 4", 
	BOY5 AS "Son 5", 
	GIRL1 AS "Daughter 1", 
	GIRL2 AS "Daughter 2", 
	GIRL3 AS "Daughter 3", 
	GIRL4 AS "Daughter 4", 
	GIRL5 AS "Daughter 5",

	ACADEMIC1DEGREENAME AS "Degree Name1",
    TRUNC(ACADEMIC1_FROM) AS "From" ,
	TRUNC(ACADEMIC1_TO) AS "To" ,
	TRUNC(ACADEMIC1_PASSINGYEAR) AS "Passing Year" ,
    ACADEMIC1INSTITUTIONNAME AS "College/School Name",
    ACADEMIC1SUBJECT AS "Major Subject",

    ACADEMIC2DEGREENAME AS "Degree Name2",
    TRUNC(ACADEMIC2_FROM) AS "From" ,
	TRUNC(ACADEMIC2_TO) AS "To" ,
	TRUNC(ACADEMIC2_PASSINGYEAR) AS "Passing Year" ,
    ACADEMIC2INSTITUTIONNAME AS "College/School Name",
    ACADEMIC2SUBJECT AS "Major Subject",

    ACADEMIC3DEGREENAME AS "Degree Name3",
    TRUNC(ACADEMIC3_FROM) AS "From" ,
	TRUNC(ACADEMIC3_TO) AS "To" ,
	TRUNC(ACADEMIC3_PASSINGYEAR) AS "Passing Year" ,
    ACADEMIC3INSTITUTIONNAME AS "College/School Name",
    ACADEMIC3SUBJECT AS "Major Subject",

    ACADEMIC4DEGREENAME AS "Degree Name4",
    TRUNC(ACADEMIC4_FROM) AS "From" ,
	TRUNC(ACADEMIC4_TO) AS "To" ,
	TRUNC(ACADEMIC4_PASSINGYEAR) AS "Passing Year" ,
    ACADEMIC4INSTITUTIONNAME AS "College/School Name",
    ACADEMIC4SUBJECT AS "Major Subject",

    ACADEMIC5DEGREENAME AS "Degree Name5",
    TRUNC(ACADEMIC5_FROM) AS "From" ,
	TRUNC(ACADEMIC5_TO) AS "To" ,
	TRUNC(ACADEMIC5_PASSINGYEAR) AS "Passing Year" ,
    ACADEMIC5INSTITUTIONNAME AS "College/School Name",
    ACADEMIC5SUBJECT AS "Major Subject", 

	CURRENTCOMPANY  AS "Current Company",
    "employeraddress" as "Current Company Address",
    "telephone" as "Current Company  Telephone",
    "fax" as "Current Company Fax",
    "initialdesignation" as "Initial Designation",
	CURRENTCOMPANYDESIGNATION AS "Current Designation", 
	TRUNC(CURRENTCOMPANYFROM) AS "From", 
	TRUNC(CURRENTCOMPANYTO) AS "To" ,
    "reasonforchange" as "Reason for Change",

	PREVIOUSCOMPANY1 AS "Previous Company 1" , 
	TRUNC(PREVIOUSCOMPANY1_FROM) AS " From" , 
	TRUNC(PREVIOUSCOMPANY1_TO) AS " To" , 
    PREVIOUSCOMPANY1DEPTNAME as "Department Name",
    PREVIOUSCOMPANY1RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY1CTC AS "CTC", 
    PREVIOUSCOMPANY1EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY2 AS "Previous Company 2" , 
	TRUNC(PREVIOUSCOMPANY2_FROM) AS "From " , 
	TRUNC(PREVIOUSCOMPANY2_TO) AS " To " ,
    PREVIOUSCOMPANY1DEPTNAME as "Department Name",
    PREVIOUSCOMPANY1RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY1CTC AS "CTC", 
    PREVIOUSCOMPANY1EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY3 AS "Previous Company 3", 
	TRUNC(PREVIOUSCOMPANY3_FROM) AS "  From" , 
	TRUNC(PREVIOUSCOMPANY3_TO) AS "To  " ,
    PREVIOUSCOMPANY3DEPTNAME as "Department Name",
    PREVIOUSCOMPANY3RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY3CTC AS "CTC", 
    PREVIOUSCOMPANY3EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY4 AS  "Previous Company 4" , 
	TRUNC(PREVIOUSCOMPANY4_FROM) AS "From  " , 
	TRUNC(PREVIOUSCOMPANY4_TO) AS "   To", 
    PREVIOUSCOMPANY4DEPTNAME as "Department Name",
    PREVIOUSCOMPANY4RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY4CTC AS "CTC", 
    PREVIOUSCOMPANY4EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY5 AS "Previous Company 5", 
	TRUNC(PREVIOUSCOMPANY5_FROM) AS  " From " , 
	TRUNC(PREVIOUSCOMPANY5_TO) AS "To   " , 
    PREVIOUSCOMPANY5DEPTNAME as "Department Name",
    PREVIOUSCOMPANY5RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY5CTC AS "CTC", 
    PREVIOUSCOMPANY5EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY6 AS "Previous Company 6", 
	TRUNC(PREVIOUSCOMPANY6_FROM) AS "  From  ", 
	TRUNC(PREVIOUSCOMPANY6_TO) AS "  To  " ,
    PREVIOUSCOMPANY6DEPTNAME as "Department Name",
    PREVIOUSCOMPANY6RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY6CTC AS "CTC", 
    PREVIOUSCOMPANY6EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY7 AS "Previous Company 7", 
	TRUNC(PREVIOUSCOMPANY7_FROM)  AS "From    ", 
	TRUNC(PREVIOUSCOMPANY7_TO) AS "To    ",
    PREVIOUSCOMPANY7DEPTNAME as "Department Name",
    PREVIOUSCOMPANY7RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY7CTC AS "CTC", 
    PREVIOUSCOMPANY7EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY8 AS "Previous Company 8", 
	TRUNC(PREVIOUSCOMPANY8_FROM) AS "    From" , 
	TRUNC(PREVIOUSCOMPANY8_TO) AS "    To" , 
    PREVIOUSCOMPANY8DEPTNAME as "Department Name",
    PREVIOUSCOMPANY8RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY8CTC AS "CTC", 
    PREVIOUSCOMPANY8EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY9  AS "Previous Company 9", 
	TRUNC(PREVIOUSCOMPANY9_FROM)  AS "From     " , 
	TRUNC(PREVIOUSCOMPANY9_TO) AS "To     " ,
    PREVIOUSCOMPANY9DEPTNAME as "Department Name",
    PREVIOUSCOMPANY9RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY9CTC AS "CTC", 
    PREVIOUSCOMPANY9EXPERIENCE AS "Experience",

	PREVIOUSCOMPANY10  AS "Previous Company 10", 
	TRUNC(PREVIOUSCOMPANY10_FROM) AS " From   " , 
	TRUNC(PREVIOUSCOMPANY10_TO)  AS "  To "  ,
    PREVIOUSCOMPANY10DEPTNAME as "Department Name",
    PREVIOUSCOMPANY10RESPONSIBILITIES AS "Responsibilities",
    PREVIOUSCOMPANY10CTC AS "CTC", 
    PREVIOUSCOMPANY10EXPERIENCE AS "Experience",
    EMAIL,
    PHOTOGRAPHSSTATUS,
    
    account_number as AccountNumber,
    bank_name as BankName,
    ifsc_code as IFSCCode,
    
    "Monthly_Basic",
    "Yearly_Basic",
    "Monthly_HRA_CLA",
    "Yearly_HRA_CLA",
    "Monthly_Conveyance",
    "Yearly_Conveyance",
    "Monthly_SpecialAllowance",
    "Yearly_SpecialAllowance",
    "Monthly_LTA",
    "Yearly_LTA",
    "Monthly_Medical",
    "Yearly_Medical",
    "Monthly_Bonus",
    "Yearly_Bonus",
    "Monthly_PF",
    "Yearly_PF",
    "Monthly_Gratuity",
    "Yearly_Gratuity",
    "Monthly_Superannuation",
    "Yearly_Superannuation",
    "Monthly_Others",
    "Yearly_Others",
    "Monthly_Total",
    "Yearly_Total",
    "ctcexpected" as CTCExpected,
    "presentjobresponsisblities" as PresentJobResponsisblities,
    "positionstructure" as PositionStructure,
    "contributioninforpastemployer" as ContributionInforpastEmployer,
    "membershipofprofessionalorganisation" as MembershipOfProfessionalOrganisation,
    "trainingprogrammeattended" as TrainingProgrammeAttended
   FROM "LGROBDB"."TBLEMPLYOEE_REPORT" where NVL( Trim(FullName),'') is not null;

END PROC_Get_EmployeeDetails_Report;