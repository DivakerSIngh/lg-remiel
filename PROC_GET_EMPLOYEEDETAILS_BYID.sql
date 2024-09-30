create or replace PROCEDURE           "PROC_GET_EMPLOYEEDETAILS_BYID" 
(
 sMode IN VARCHAR  DEFAULT 'GetPersoanlDetails',
 P_EmployeeId IN INT DEFAULT 0,
 C_Details out SYS_REFCURSOR
)
AS 
BEGIN
IF sMode='GetPersoanlDetails' THEN


 OPEN C_Details FOR
SELECT 
    te.*,
     te.image_url as ImageUrl,
    j.JobTitle as Positionapplied,
    padd.Address as PresentAddress, 
    padd.Pincode as PresentAddressPin, 
    padd.Telephone as PresentAddressTelephone, 
    pstate.Id as PresentState,
    padd.city as PresentCity,
    eadd.Address as PermanentAddress, 
    eadd.Pincode as PermanentAddressPin, 
    eadd.Telephone as PermanentAddressTelephone,
    s.Id as PermanentState,
    eadd.city as PermanentCity,
    tedd.FullName as FatherName 
FROM tblEmployee te
	left JOIN tblEmployee_Address padd 
       left join tblmastardata pstate on pstate.ID = padd.state
       -- join tblcitymaster pcity on pcity.ID =  padd.city
    ON padd.EmployeeId = te.Id and padd.Ispresentaddress = 1 
    left JOIN tblEmployee_Address eadd 
        join tblmastardata s on s.ID = eadd.state
      --  join tblcitymaster c on c.ID =  eadd.city
    ON eadd.EmployeeId = te.Id and eadd.Ispresentaddress = 0
	left JOIN tblEmployee_DependentsDetails tedd 
        join tblmastardata md on tedd.Relationship = md.id and md.value = 'Father'
     ON tedd.EmployeeId = te.Id and tedd.isdeleted = 0
    join tbljobs j on j.id = te.jobId
WHERE nvl(te.isdeleted,0)=0 
    and te.Id = P_EmployeeId;
END IF;




END PROC_Get_EmployeeDetails_ById;