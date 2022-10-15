create database hr_database;
\c hr_database


-- creating staging table
create table stg_hr (EMP_ID varchar(10),	EMP_NM varchar(25),	EMAIL varchar(100),	HIRE_DT date,	JOB_TITLE varchar(50),	SALARY money,	DEPARTMENT varchar(25),	MANAGER varchar(25),	START_DT date,	END_DT date,	LOCATION varchar(25),	ADDRESS varchar(150),CITY varchar(25),	STATE char(2),	EDUCATION_LEVEL varchar(50));	

-- importing data from the flat file 'kindly change the directory'
copy stg_hr from '/home/hanafy01/Documents/Work/Data Architect/Part_01/project/submission_01/hr-dataset.csv'
delimiter ',' csv header;


-- at first glance scrutinizing the dataset I found that there are no duplicate rows though there are plenty of repeated values 

select emp_id, emp_nm,EMAIL,count(*)
from stg_hr
group by emp_id, emp_nm,EMAIL
HAVING count(emp_id) > 1;

select emp_id from stg_hr group by emp_id HAVING count(*) > 1;

-- there are 6 employees who occupy two Job titles at the same time 

select* from stg_hr where EMP_ID in ('E27498','E16678','E13160','E15292','E20848','E23295') ORDER BY emp_id;

-- after a deeper look found that those six employees occupied those job titles in different periods and the older job title is always the one with smaller salary that means that the employee has been upgraded at the second job title starting date 


select manager,count(*) from stg_hr group by manager having count(*) >= 1;

-- have 5 managers in the whole database we would better give them their own table 

select * from stg_hr where manager ='#N/A';

-- that is the president of ACB Corp. 


------------------------------------------------------------------------------------------------------------


-- creating employee table 
create table employee(emp_id varchar(10) primary key,emp_nm varchar(25),HIRE_DT date);
-- populating employee table
insert into employee(emp_id,emp_nm,HIRE_DT) select distinct EMP_ID,EMP_NM,HIRE_DT from stg_hr; 
-- let's check the new table 
select* from employee limit 10 ;

-- we can not have employees emails in the employee table due to transitive property (3NF)
-- creating employee_email table 

create table employee_email(emp_id varchar(10) primary key references employee(emp_id), email varchar(100));
-- populating employee_email table
insert into employee_email(emp_id,email) select distinct EMP_ID,email from stg_hr; 
-- let's check the new table 
select* from employee_email limit 10;


-- creating Job_title table
create table Job_title(Job_title_id serial primary key , Job_title varchar(50));
-- populating Job_title table
insert into Job_title(Job_title) select distinct Job_title from stg_hr;
-- let's check the new table 
select* from Job_title;


-- creating salary table for security 
-- all salaries are unique values 
 create table salary(salary_id serial primary key , salary money);
-- populating salary table
insert into salary(salary) select distinct salary from stg_hr;
-- let's check the new table 
select* from salary limit 10;


-- creating department table
create table department(department_id serial primary key , department varchar(25));
-- populating department table
insert into department(department) select distinct department from stg_hr;
-- let's check the new table 
select* from department;


-- creating manager table
create table manager(manager_id serial primary key, manager varchar(25));
-- populating manager table
insert into manager(manager) select distinct manager from stg_hr;
-- let's check the new table 
select* from manager;


-- as ACP Corp. does not have any shipping activities related to its products it will save time and effort to make just one address column and use it for every company location as they will always be fixed addresses and we also only have a total of five locations  


-- creating location table
create table location(location_id serial primary key ,location varchar(25), full_address varchar(150));
-- populating location table
insert into location(location,full_address) select distinct location,concat(ADDRESS, ',',CITY,',' ,STATE) from stg_hr;
-- let's check the new table 
select* from location;
--well it's better to move full addresses to their own table due to transitive property (3NF) between location and full_address columns 
create table address(location_id int primary key references location(location_id), full_address varchar(150));
insert into address(location_id, full_address) select distinct location_id,full_address from location;
-- droping the full_address column from location table
alter table location drop full_address;
-- check our work
select* from address;
select* from location; 

-------------

-- creating EDUCATION table
create table EDUCATION(EDUCATION_id serial primary key ,EDUCATION_LEVEL varchar(50));
-- populating EDUCATION  table
insert into EDUCATION(EDUCATION_LEVEL) select distinct EDUCATION_LEVEL from stg_hr;
-- let's check the new table 
select* from EDUCATION;


-------------------------------------------------------------------------

-- creating job table 

create table job(job_id serial primary key,
                 EMP_ID varchar(10) references employee(EMP_ID),
                 JOB_title_id int references Job_title(Job_title_id),
                 salary_id int references salary(salary_id),
                 department_id int references department(department_id),
                 manager_id int references manager(manager_id),
                 START_DT date,	
                 END_DT date,	
                 location_id int references location(location_id),	
                 EDUCATION_id int references EDUCATION(EDUCATION_id));
                 
                 


insert into job(EMP_ID,JOB_TITLE_id,salary_id,department_id,manager_id,START_DT,END_DT,location_ID,EDUCATION_id) 
select stg.EMP_ID,jt.JOB_TITLE_id,s.salary_id,d.department_id,m.manager_id,stg.START_DT,stg.END_DT,loc.location_ID,ed.EDUCATION_id 
from stg_hr as stg 
join job_title as jt on jt.job_title = stg.job_title 
join salary as s on s.salary = stg.salary 
join department as d on d.department = stg.department 
join manager as m on m.manager = stg.manager
join location as loc on loc.location = stg.location
join EDUCATION as ed on ed.education_level = stg.education_level;

-- check job table
select* from job limit 10;




-- CRUD
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- Question 1: Return a list of employees with Job Titles and Department Names

select emp_nm,job_title,department 
from job,employee,job_title,department 
where job.emp_id=employee.emp_id 
and job.job_title_id = job_title.job_title_id 
and department.department_id = job.department_id ;

---------------------------------------------------------------------------------------

-- Question 2: Insert Web Programmer 
-- as a new job title

insert into job_title(job_title) 
values ('Web Programer');

select* from job_title;

---------------------------------------------------------------------------------------

-- Question 3: Correct the job title 
-- from web programmer to web developer

update job_title set job_title = 'web developer' where  job_title = 'Web Programer';

select* from job_title;
--------------------------------------------------------------------------------------

-- Question 4: Delete the job title Web Developer from the database

delete from job_title 
where job_title = 'web developer';
select* from job_title;
---------------------------------------------------------------------------------------

-- Question 5: How many employees are in each department?


select department,count(emp_id) 
from job,department 
where job.department_id = department.department_id 
and (end_dt >= '2022-09-17' or end_dt is null)
group by department;

---------------------------------------------------------------------------------------

--Question 6: Write a query that returns current and past jobs (include employee name, job title, department, manager name, start and end date for position) for employee 'Toni Lembeck'.


select emp_nm,job_title,department,manager,start_dt,end_dt 
from job,employee,job_title,department,manager 
where job.emp_id = employee.emp_id 
and job.job_title_id = job_title.job_title_id 
and job.department_id = department.department_id 
and job.manager_id = manager.manager_id and emp_nm = 'Toni Lembeck'; 

---------------------------------------------------------------------------------------
--Question 7: Describe how you would apply table security to restrict access to employee salaries using an SQL server.



-- I will  revoke the employees who do not belong to HR or Management departments from salary table and grant them read only access to the rest of the database while HR & Management (10%) will be granted full control of the whole database read/write
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- standout suggestion #1: Create a view that returns all employee attributes; results should resemble initial Excel file

create view employee_full_data as 
select j.emp_id,e.emp_nm,ee.email,e.hire_dt,jt.job_title,s.salary,d.department
,m.manager,j.start_dt,j.end_dt,l.location
,ad.full_address,ed.EDUCATION_level 
from job as j 
join employee as e on e.emp_id = j.emp_id 
join employee_email as ee on ee.emp_id = e.emp_id
join job_title as jt on jt.job_title_id = j.job_title_id
join salary as s on s.salary_id = j.salary_id
join department as d on d.department_id = j.department_id
join manager as m on m.manager_id = j.manager_id
join location as l on l.location_id = j.location_id
join address as ad on ad.location_id = l.location_id
join EDUCATION as ed on ed.EDUCATION_id = j.EDUCATION_id;

-- let's check it out 
select* from employee_full_data;

---------------------------------------------------------------------------------------

-- standout suggestion #2: Create a stored procedure with parameters that returns current and past jobs (include employee name, job title, department, manager name, start and end date for position) when given an employee name.


create PROCEDURE Employee_jobs(employee_name varchar(25))
LANGUAGE SQL
AS $$
select emp_nm,job_title,department,manager,start_dt,end_dt from job,employee,job_title
,department,manager 
where job.emp_id = employee.emp_id and job.job_title_id = job_title.job_title_id 
and job.department_id = department.department_id and job.manager_id = manager.manager_id 
and emp_nm = (employee_name);
$$;
-- let's use to the procedure with the parameter('Toni Lembeck');
call Employee_jobs('Toni Lembeck');

-------------------------------------------------------------------


-- standout suggestion #3:Implement user security on the restricted salary attribute.
-- Create a non-management user named NoMgr. Show the code of how your would grant access to the database,
-- but revoke access to the salary data.


create user NoMgr password 'NoMgr123';
grant connect on database hr_database to NoMgr;

grant select on job,employee,employee_email,job_title,
department,manager,education,location,address 
to read_only_no_salary;

revoke all on salary from NoMgr;





	





























