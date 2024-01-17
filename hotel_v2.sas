/*
DP SAS Assignment 1 2023 
hotel_v2.sas updated 2023-03-16
Question 1: Hotel reservations

Name:Laila Lima Alves
Student ID: 14344509


Complete the missing code between the numbered comments.
Save and submit the completed SAS file.

Erratum:
2023-03-16 arrival_date -> arrival in Q1.3, 1.4, 1.5, 1.6, 1.7
Edited to make the task easier

[1.1] Import the Hotel Reservations data into a temporary dataset `hotel` 
*/


PROC IMPORT DATAFILE='/home/u60923758/A2023/A1/Hotel Reservations.csv'
	DBMS=CSV
	OUT=work.hotel
	replace;
	GETNAMES=YES;
RUN;


/*
[1.2] Check the imported data.
Show which variables contain the booking date, and their format.
*/


title1 "[1.2] Check the imported data";
ODS NOPROCTITLE;
proc contents data=work.hotel;
run;




title1 "[1.2] Check the imported data";
title2 "Variables with booking date information are all numerical";
ODS NOPROCTITLE;
proc print data=work.hotel (obs=10);
var arrival_date	arrival_month	arrival_year;
run;


/* 
[1.3] Create a new variable `arrival`
that contains a SAS date
made out of arrival_month, arrival_date, arrival_year
and assign a permanent date format to the new variable
*/



data work.hotel;
set work.hotel;
arrival = mdy(arrival_month,arrival_date,arrival_year);
format arrival MMDDYY10.;
run; *Warnings: 29th February not being accepted as date;



/* 
[1.4] To check your calculation,
print arrival arrival_year arrival_month arrival_date
for the first 10 rows of `hotel` dataset
*/



title1 "[1.3] Create a new variable `arrival` & [1.4] To check your calculation";
title2 "Compare new created column 'arrival' with original source columns";
ODS NOPROCTITLE;
proc print data=work.hotel (obs=10);
var arrival arrival_month  arrival_date  arrival_year;
run;



/* 
[1.5] Calculate the number of bookings for each quarter (e.g. 2017/3, 2017/4, ...)
only for bookings where the booking status is "Not_Canceled"
hint: apply a temporary date format to arrival
	so it's displayed as 2017/4 instead of 02OCT2017
	(any date format that generates quarters is fine)
Show the number and percentage of bookings for each quarter.
*/


Title1 "[1.5] Calculate the number of bookings for each quarter";
Title2 "Overview number and % of bookings with 'Not Canceled' status per quarter";
ODS NOPROCTITLE;
Proc freq data=work.hotel;
format arrival yyq10.;
tables arrival;
where booking_status eq "Not_Canceled"; 
run;


/* 
[1.6] Print rows where arrival is missing, see if there's a pattern
*/


Title1 "[1.6] Print rows where arrival is missing, see if there's a pattern";
Title2 "Rows with missing values in column arrival";
Footnote "Note: Rows with arrival date on 29-02-2018 have missing values because 2018 was not a leap year";
ODS NOPROCTITLE;
proc print data=work.hotel (obs=15);
var arrival arrival_date  arrival_month arrival_year;
where arrival is missing;
run; 

Footnote;



title1 "Frequency of years original File Hotel";
title2 "Check years date in the file to validate warnings during transformation";
Footnote "The file has two distinct years availabe (2017, 2018), though none of them has 29 days in February";
ODS NOPROCTITLE;
proc freq data=work.hotel;
tables arrival_year;
run;

Footnote;


/*
[1.7] Remove rows from `hotel` where arrival is missing
then re-run the table from Q1.5 to confirm.
*/

*permanently remove the rows with missing value at column arrival and name it hotel1;
data hotel1;
set work.hotel;
where not missing (arrival);
run; 


/* OPTION 2
data hotel1;
set work.hotel;
if missing(arrival) then delete;
run;
*/ 



Title1 "[1.7] New File without missing values";
Title2 "Overview number and % of bookings with 'Not Canceled' status per quarter excluding missing values";
ODS NOPROCTITLE;
Proc freq data=work.hotel1;
format arrival yyq10.;
tables arrival;
where booking_status eq "Not_Canceled"; 
run;



/* 
Make a results table 
showing the average price 
of each room type
in order of frequency
also showing minimum, median, and maximum 
*/


title1 "View of File Hotel1";
title2 "Most popular room type and price statistics for each one";
ODS NOPROCTITLE;
proc means data=hotel1 min median mean max maxdec=0 order=freq;
	var avg_price_per_room;
	class room_type_reserved;
run;


/* 
[1.8] Room types 1 and 4 are the most common
Rename them with a custom format
	Room_Type 1: Budget
	Room_Type 4: City View
	others	   : Other
Group the other room types together
Apply the format permanently to the `hotel` dataset
*/


/* 
Use the function proc format to create the required format and 
include them permanently in the file hotel3b in the column room_type_reserved
*/


PROC FORMAT; 
VALUE $room_class 'Room_Type 1'='Budget'
				  'Room_Type 4' ='City View'
				  'Room_Type 2' ='Other'
				  'Room_Type 3' ='Other'
				  'Room_Type 5' ='Other'
				  'Room_Type 6' ='Other'
				  'Room_Type 7' ='Other';
run;


data work.hotel1;
	set work.hotel1;
	where room_type_reserved is not missing;
	format room_type_reserved $room_class.;
run;



Title1 "[1.8] Rename most comon room types with a custom format";
Title2 "statistical values with content replacement at column 'room_type_reserved'";
proc means data=hotel1 min median mean max maxdec=0 order=freq;
	var avg_price_per_room;
	class room_type_reserved;
run;


/* 
Calculate detailed statistics for Budget and City View rooms
and find out what winsorising the most extreme 10% of values would do
*/


proc sort data=hotel1;
	by room_type_reserved;
run;


title "Avg_price_per_room detailed statistics for room type Budget and City View";
ODS NOPROCTITLE;
proc univariate data=hotel1 winsorized=0.1;
	var avg_price_per_room;
	by room_type_reserved;
	where room_type_reserved in ("Room_Type 1", "Room_Type 4");
run;



/* 
[1.9] 
Replace outliers in room_type_reserved by winsorizing
Put the transformed data into a new dataset `hotel_winsorized`

1. Define 4 macro variables: type_1_p05 type_1_p95 type_4_p05 type_4_p95
2. Set type_1_p05 and type_1_p95 to the 5% and 95% values for Room_Type 1 (Budget)
3. Set type_4_p05 and type_4_p95 to the 5% and 95% values for Room_Type 4 (City View)
4. Using one DATA step:
4a. Make a new dataset `hotel_winsorized`
4b. Using one multiple conditional processing clause AND YOUR MACRO VARIABLES:
	For "Room_Type 1" rows, 
		if avg_price_per_room is below the p05 cutoff, set it to p05 for room type 1
		if avg_price_per_room is above the p95 cutoff, set it to p95 for room type 1
	For "Room_Type 4" rows,
		if avg_price_per_room is below the p05 cutoff, set it to p05 for room type 4
		if avg_price_per_room is above the p95 cutoff, set it to p95 for room type 4
4c. Only put rows into hotel_winsorized if they are for Budget or City View bookings
*/


/* Query:
https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/procstat/procstat_univariate_examples08.htm
https://blogs.sas.com/content/iml/2013/10/23/percentiles-in-a-tabular-format.html
https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/procstat/procstat_univariate_examples08.htm

Create a new file only with the Budget or City View bookings*/

data hotel2;
set hotel1;
where room_type_reserved in ("Room_Type 1", "Room_Type 4");
run;


/* Calculate the percentiles for each room type requested, 
they are similar to the values seen on previous univariate analysis, 
therefore will not print them again
Total observations Budget = 28105
Total observations City view = 6049 */


proc univariate data=hotel2 noprint;
var avg_price_per_room;
by room_type_reserved;
run;



/*  Manually write down the limits for 5th and 95th percentiles, as we have not seen how to link macros to file outputs 
room_type_reserved 'Budget' with Lower 5th Perentile = 60.4
room_type_reserved 'Budget' with Higher 95th Perentile = 141
room_type_reserved 'City View' with Lower 5th Perentile = 69.22
room_type_reserved 'City View' with Higher 95th Perentile = 176 
*/ 


%let type_1_p05 = 60.4;
%let type_1_p95 = 141;
%let type_4_p05 = 69.22;
%let type_4_p95 = 176;


data hotel_winsorized;
	set hotel2;
	winsorized = avg_price_per_room;
	format winsorized best12.;
	if room_type_reserved = 'Room_Type 1' then do;
		if avg_price_per_room le "&type_1_p05" then winsorized = "&type_1_p05";
		else if avg_price_per_room ge "&type_1_p95" then winsorized = "&type_1_p95";
	end;
	else if room_type_reserved = 'Room_Type 4' then do;
        if avg_price_per_room le "&type_4_p05" then winsorized = "&type_4_p05" ;
        else if avg_price_per_room ge "&type_4_p95" then winsorized = "&type_4_p95";
	end;	
run;



* since I created an additional column with the winzoried price values, 
the calcuations need to be done on variable winsorized;
Title1 "[1.9] Replace outliers in room_type_reserved by winsorizing";
Title2 "Confirmation that the lowest values are all replaced by the 5% percentile, while highest values are replaced by 95% percentile";
proc univariate data=hotel_winsorized;
var winsorized;
by room_type_reserved;
run;



/*
Calculate the final price range after winsorizing
Produce one result table with the minimum, mean, and maximum values of avg_price_per_room
With one row for Budget and one row for City View
Apply a temporary label to room_type_reserved so it looks nice
*/


title "Cont.[1.9] Price range for Budget and City View rooms";
footnote "10% most extreme values were winsorised";
proc means data=hotel_winsorized min mean max maxdec=0;
	var winsorized;
	class room_type_reserved;
	label room_type_reserved="Room type";
run;

/* ends */
