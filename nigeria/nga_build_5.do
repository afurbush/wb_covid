* Project: WB COVID
* Created on: August 2020
* Created by: jdm
* Edited by: amf
* Last edited: Nov 2020 
* Stata v.16.1

* does
	* reads in fifth round of Nigeria data
	* reshapes and builds panel
	* outputs panel data 

* assumes
	* raw Nigeria data

* TO DO:
	* complete


* **********************************************************************
* 0 - setup
* **********************************************************************

* define 
	global	root	=	"$data/nigeria/raw"
	global	export	=	"$data/nigeria/refined"
	global  fies 	= 	"$data/analysis/raw/Nigeria"

* set local wave number & file number
	local			w = 5
	
* make wave folder within refined folder if it does not already exist 
	capture mkdir "$export/wave_0`w'" 
		
				
* ***********************************************************************
* 1 - format secitons and save tempfiles
* ***********************************************************************


* ***********************************************************************
* 1a - section 2: household size and gender of HOH
* ***********************************************************************
	
* load data
	use				"$root/wave_0`w'/r`w'_sect_2.dta", clear

* rename other variables 
	rename 			indiv ind_id 
	rename 			s2q2 new_mem
	rename 			s2q3 curr_mem
	rename 			s2q5 sex_mem
	rename 			s2q6 age_mem
	rename 			s2q7 relat_mem
	
* generate counting variables
	gen				hhsize = 1
	gen 			hhsize_adult = 1 if age_mem > 18 & age_mem < .
	gen				hhsize_child = 1 if age_mem < 19 & age_mem != . 
	gen 			hhsize_schchild = 1 if age_mem > 4 & age_mem < 19 
	
* create hh head gender
	gen 			sexhh = . 
	replace			sexhh = sex_mem if relat_mem == 1
	label var 		sexhh "Sex of household head"
	
* collapse data
	collapse		(sum) hhsize hhsize_adult hhsize_child hhsize_schchild (max) sexhh, by(hhid)
	lab var			hhsize "Household size"
	lab var 		hhsize_adult "Household size - only adults"
	lab var 		hhsize_child "Household size - children 0 - 18"
	lab var 		hhsize_schchild "Household size - school-age children 5 - 18"

* save temp file
	tempfile		tempa
	save			`tempa'

	
* ***********************************************************************
* 1b - sections 3-6, 8-9, 12: respondant gender
* ***********************************************************************

* load data
	use				"$root/wave_0`w'/r`w'_sect_a_2_5c_6_12", clear
	
* drop all but household respondant
	keep			hhid s12q9
	rename			s12q9 indiv
	isid			hhid
	
* merge in household roster
	merge 			1:1	hhid indiv using "$root/wave_0`w'/r`w'_sect_2.dta"
	keep 			if _merge == 3
	drop 			_merge
	
* rename variables and fill in missing values
	rename			s2q5 sex
	rename			s2q6 age
	rename			s2q7 relate_hoh
	replace			relate_hoh = s2q9 if relate_hoh == .
	rename			indiv PID
	
* drop all but gender and relation to HoH
	keep			hhid PID sex age relate_hoh

* save temp file
	tempfile		tempb
	save			`tempb'

	
* ***********************************************************************
* 1c - section 7: income
* ***********************************************************************

* load data
	use				"$root/wave_0`w'/r`w'_sect_7", clear

* reformat HHID
	format 			%5.0f hhid
	
* drop other source
	drop			zone state lga sector ea
	
* reshape data	
	reshape 		wide s7q1, i(hhid) j(source_cd)

	rename			s7q14 oth_inc_1
	lab var 		oth_inc_1 "Other Income: Remittances from abroad"
	rename			s7q15 oth_inc_2
	lab var 		oth_inc_2 "Other Income: Remittances from family in the country"
	rename			s7q16 oth_inc_3
	lab var 		oth_inc_3 "Other Income: Assistance from non-family"
	rename			s7q17 oth_inc_4
	lab var 		oth_inc_4 "Other Income: Income from properties, investments, or savings"
	rename			s7q18 oth_inc_5
	lab var 		oth_inc_5 "Other Income: Pension"
	
* save temp file
	tempfile		tempc
	save			`tempc'

	
* ***********************************************************************
* 1d - section 11: assistance
* ***********************************************************************	
	
* not avaiable for round 
	
		
* ***********************************************************************
* 1e - section 10: shocks
* ***********************************************************************

* not avaiable for round

	
* ***********************************************************************
* 2 - FIES score
* ***********************************************************************

* not available for round 

	
* ***********************************************************************
* 3 - merge sections into panel and save
* ***********************************************************************

* merge sections based on hhid
	use				"$root/wave_0`w'/r`w'_sect_a_2_5c_6_12", clear
	foreach 		s in a b c {
	    merge		1:1 hhid using `temp`s'', nogen
	}
	
* generate round variable
	gen				wave = `w'
	lab var			wave "Wave number"	

* clean variables inconsistent with other rounds	
	rename			s6q16 ag_crop
	rename 			s6bq1 ag_live
 	
* save round file
	save			"$export/wave_0`w'/r`w'", replace
	
	
/* END */	