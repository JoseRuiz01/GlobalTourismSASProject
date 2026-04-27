/* ============================================================
   STEP 1: Clean and standardize the raw tourism dataset.
   - Retains country name and tourism type across rows
   - Drops unused year columns (1995-2013)
   - Extracts embedded labels mixed in with data rows
   - Standardizes missing values and series codes
   ============================================================ */
DATA cleaned_tourism;
	LENGTH Country_Name $300 Tourism_Type $20;
	RETAIN Country_Name Tourism_Type;
	
	SET work.tourism(DROP= _1995-_2013);
	
		IF A ^= "." THEN Country_Name=Country;
		
		IF UPCASE(Country) = "INBOUND TOURISM" THEN Tourism_Type = "Inbound Tourism";
		ELSE IF UPCASE(Country) = "OUTBOUND TOURISM" THEN Tourism_Type = "Outbound Tourism";
		
		IF UPCASE(Country) = UPCASE(Country_Name) OR UPCASE(Country) = UPCASE(Tourism_Type) THEN DELETE;
		
		IF Series = ".." OR Series = "." THEN Series = ".";
		ELSE Series = UPCASE(Series);
		
		ConversionType = STRIP(SCAN(Country,-1," "));
		
		IF _2014 = ".." OR _2014 = "." THEN _2014 = ".";
RUN;


/* ============================================================
   STEP 2: Split cleaned data into two separate output tables.
   - expenditures: rows measured in millions (Mn), scaled to USD
   - tourists:     rows measured in thousands, scaled to count
   - Converts _2014 from character to numeric
   ============================================================ */
DATA tourists(DROP=Expenditures2014) expenditures(DROP=Tourists2014);
	SET cleaned_tourism;
	Num_2014 = INPUT(_2014, 16.);
	
	FORMAT Expenditures2014 dollar25.
           Tourists2014 comma25.;
           
	IF ConversionType = "Mn" THEN DO;
		Category = CATX(" - ", SCAN(Country, 1, "-"), "US$");
		IF Num_2014= . THEN Expenditures2014 = .;
		ELSE Expenditures2014 = Num_2014*1000000;
		OUTPUT expenditures;
	END;
	
	ELSE IF ConversionType = "Thousands" THEN DO;
		Category = SCAN(Country, 1, "-");
		IF Num_2014 = . THEN Tourists2014 = .;
		ELSE Tourists2014 = Num_2014*1000;
		OUTPUT tourists;
	END;
	
	DROP A ConversionType Country Num_2014 _2014;
RUN;


/* ============================================================
   STEP 3: Define a custom format to decode numeric continent
   codes into human-readable region names.
   ============================================================ */
PROC FORMAT FMTLIB;
	VALUE CONTINENTS 	1 =	"North America"
						2 =	"South America"
						3 =	"Europe"
						4 =	"Africa"
						5 =	"Asia"
						6 =	"Oceania"
						7 =	"Antarctica";
RUN;


/* ============================================================
   STEP 4: Sort country metadata by Country_Name to prepare
   for the merge in the next step.
   ============================================================ */
PROC SORT DATA=country_info(RENAME=(Country=Country_Name)) OUT=country_sorted;
	BY Country_Name;
RUN;


/* ============================================================
   STEP 5a: Merge expenditures with country metadata.
   - Adds continent information to each row
   - Applies custom CONTINENTS format to decode numeric codes
   - Keeps only rows matched in both datasets (inner join)
   ============================================================ */
DATA final_expenditures;
	MERGE expenditures(in=inExp) 
		country_sorted(in=inCountry);
	BY Country_Name;
	ContinentName=PUT(Continent, CONTINENTS.);
	IF inExp=1 AND inCountry=1;
	DROP Continent;
RUN;


/* ============================================================
   STEP 5b: Same merge logic applied to the tourists table.
   ============================================================ */
DATA final_tourists;
	MERGE tourists(in=inTourists) 
		country_sorted(in=inCountry);
	BY Country_Name;
	ContinentName=PUT(Continent, CONTINENTS.);
	IF inTourists=1 AND inCountry=1;
	DROP Continent;
RUN;


/* ============================================================
   STEP 6: Transpose expenditures from long to wide format.
   - Filters for IMF total expenditure rows only
   - Groups by country, pivots Tourism_Type into columns
   - Result: one row per country with Inbound/Outbound as columns
   ============================================================ */
OPTIONS VALIDVARNAME=v7;
PROC TRANSPOSE DATA=final_expenditures OUT=expenditures_t(DROP=_name_);
	WHERE Series = "IMF" AND Category LIKE "Tourism expenditure%";
	BY Country_Name;
	VAR Expenditures2014;
	ID Tourism_Type;
RUN;


/* ============================================================
   STEP 7: Calculate percentage difference between outbound
   and inbound tourism expenditures per country.
   - Excludes rows with missing values for either direction
   ============================================================ */
DATA inOut_PC;
	SET expenditures_t;
	IF Inbound_tourism ^= . AND Outbound_tourism ^= .;
	PctChg_Out = ((Inbound_tourism-Outbound_Tourism)/(Outbound_Tourism));
	FORMAT PctChg_Out PERCENT10.;
RUN;


/* ============================================================
   STEP 8: Print countries where outbound expenditure exceeds
   inbound, filtered for the United States.
   ============================================================ */
ODS NOPROCTITLE;
PROC PRINT DATA=inOut_PC;
	WHERE PctChg_Out > 0 AND Country_Name = "UNITED STATES OF AMERICA";
RUN;
