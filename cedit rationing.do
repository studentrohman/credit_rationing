clear
capture log close
set more off
global induk D:\ifls5data\hh
global result D:\penelitinn\credit_rationing

*1.pendidikan(ind)
use $induk\bk_ar1.dta, clear 
*anak sekolah 

gen anak_sekolah=1 if ar18c==1
replace anak_sekolah=0 if  anak_sekolah~=1
label var anak_sekolah "keberadaan  anak sekolah"
label define anak_sekolah 0" tidak ada anak sekolah" 1" ada anak sekolah"
label value anak_sekolah anak_sekolah
format %12.0f anak_sekolah

*2.umur (ind)
gen inhh=(ar01a==1 | ar01a==2 | ar01a==5 | ar01a==11)
keep if inhh==1
keep if ar01i==1
*4.lama pendidikan (ind)
sort hhid14_9 pid14
by hhid14_9: gen v=_n
by hhid14_9: gen age_fath=ar09[ar10]
by hhid14_9: gen fatheduc=ar16[ar10]
by hhid14_9: gen fatheduc1=ar17[ar10]
rename fatheduc edlvl
rename fatheduc1 edgrade
gen educyr=0 				if edlvl==1				/* no schooling:  0 years of education */
  replace educyr=edgrade 	if edlvl==2 & edgrade<7 			/* elementary school, not graduated */
  replace educyr=6 			if edlvl==2 & edgrade==7			/* elementary school, graduated */
  replace educyr=6+edgrade 	if (edlvl==3 | edlvl==4) & edgrade<7			/* junior high, not graduated */
  replace educyr=9 			if (edlvl==3 | edlvl==4) & edgrade==7			/* junior high, graduated */
  replace educyr=9+edgrade 	if (edlvl==5 | edlvl==6) & edgrade <7 			/* senior high, not graduated */
  replace educyr=12 		if (edlvl==5 | edlvl==6) & edgrade ==7  		/* senior high, graduated */
 
  replace educyr=12+edgrade  if edlvl==60 & edgrade<=3      			/* college D1,D2,D3, not graduated */                  
  replace educyr=15          if edlvl==60 & edgrade>3  & edgrade<=7  	/* college D1,D2,D3, graduated */
  replace educyr=12+edgrade  if edlvl==61 & edgrade<=5          		/* university (bachelor), not graduated */
  replace educyr=17          if edlvl==61 & edgrade>5  & edgrade<=7   	/* university (bachelor, graduated) */                    
  replace educyr=17+edgrade  if edlvl==62 & edgrade<=2                      /* university (master), not graduated */      
  replace educyr=19          if edlvl==62 & edgrade>2  & edgrade<=7         /* university (master), graduated */ 	              
  replace educyr=19+edgrade  if edlvl==63 & edgrade<=3				/* university (doctorate), not graduated */
  replace educyr=22          if edlvl==63 & edgrade>3  & edgrade<=7    	/* university (doctorate), graduated */
label var educyr "lama pendidikan"
format %12.0f educyr
by hhid14_9: gen x=_n
by hhid14_9: gen size_family=_N
format %12.0f size_family
keep hhid14 pid14 age_fath educyr size_family anak_sekolah
save $result\1_jenis_keldll.dta, replace

*6.daerah tempat tinggal
use $induk\bk_sc1.dta, clear
gen tempat_tinggal=1 if sc05==1
	replace tempat_tinggal=0 if tempat_tinggal~=1
	label var tempat_tinggal "status tempat tinggal "
	label define tempat_tinggal 0"0:pedesaan" 1"1:perkota\\an"
	label value tempat_tinggal tempat_tinggal
	format %12.0f tempat_tinggal
	keep hhid14_9 hhid14 tempat_tinggal
save $result\2_tempat_tinggal.dta, replace
*7a. x5= pendapatan B2 seksi UT
use $induk\b2_ut2.dta, clear
gen farm=ut07o if ut07ox==1
	replace farm= ut07o if farm >999000000000
	format %12.0f farm
	label var farm "hasil panen(Rp)"
	keep hhid14 farm
save $result\3_panen.dta, replace
*7b. beraa kali panen
use $induk/b2_ut1.dta, clear
gen landfarm=1 if ut00a==1
	replace landfarm=0 if landfarm==.
	label var landfarm " kepemilikan tanah pertanian"
	label define landfarm 1"punya" 0"tidak punya"
	label value landfarm landfarm
	
gen times =ut07xb
	replace times=1 if times >5 & times~=.
	keep hhid14 times landfarm
save $result\4_panen.dta, replace
*7c. X5 pendapatan b2 seksi NT
use $induk\b2_nt2.dta, clear
	gen nonfarm=nt07 if nt07x==1
	gen nonform1=nonfarm if nt_num==1
	gen nonform2=nonfarm if nt_num==2
	collapse(max) nonform1 nonform2, by(hhid14)
	for var nonform1 nonform2 : replace X=0 if X==.
	gen tnfarm=nonform1+nonform2
	format %12.0f tnfarm
	label var tnfarm "total non farm income"
	keep hhid14 tnfarm
save $result\5_nonfarm.dta, replace

*8.pendapatan rumah tangga dari upah 
 use $induk\b3a_tk2.dta, clear
			gen pendapatan=tk25a1 if tk25a1x==1
			replace pendapatan=tk25a1 if pendapatan>999000000000
			replace pendapatan=pendapatan*12
			format %12.0f pendapatan
			label var pendapatan "pendapatan upah"
			keep hhid14 pid14 pendapatan
	save $result\6_upah.dta, replace
*9.debt pertahun
use $induk\b2_bh, clear 
gen get_credit= 1 if  bh04==1
	replace get_credit= 0 if  get_credit==.
	label var get_credit " memperoleh utang selma 12 tahun terakhir"
	label define get_credit 0"tidak memperoleh" 1" memperoleh"
	label value get_credit get_credit
gen debt=bh10 if bh10x==1
	replace debt=bh10 if debt >999000000000
	format %12.0f debt
	label var debt " hutang pertahun rumah tangga"
	ren bh06 insti_tolak
keep debt get_credit hhid14 insti_tolak
save $result\7_hutang.dta, replace
*12.status pekerjaan formal/informal
use $induk\b3a_tk2.dta, clear
gen pekerjaan_formal=1 if inlist(tk24a,4,5)
	replace pekerjaan_formal=0 if inlist(tk24a,1,2,3,7,8,6)
	label var pekerjaan_formal "status pekerjaan "
	label define pekerjaan_formal 0"informal" 1"formal"
	label value pekerjaan_formal pekerjaan_formal
	format %12.0f pekerjaan_formal
	keep hhid14_9 pid14 hhid14 pekerjaan_formal
save $result\8_status_formal.dta, replace
*10.pengeluaran
*pengeluaran rumah tangga 
		use $induk\b1_ks1.dta, clear 
			gen expend_food=ks03 if ks03x==1
			replace  expend_food=ks03 if expend_food >999000000000
			keep hhid14 expend_food
			format %12.0f expend_food
		save $result\9_konsum1.dta, replace
		use $induk\b1_ks2.dta, clear 	
			gen expend_nonfood=ks06 if ks06x==1
			replace expend_nonfood=ks06 if expend_nonfood >999000000000
			keep hhid14 expend_nonfood 
			format %12.0f expend_nonfood
		save $result\10_konsum2.dta, replace

			
*status kesehatan

use $induk\b3b_kk1.dta, clear
gen healthy=1 if inlist(kk01,1,2)
replace healthy=0 if inlist(kk01,3,4)
label var healthy "status kesehatan"
label define healthy 0"tidak sehat" 1"sehat"
label value healthy healthy
keep  hhid14_9 pid14 hhid14 healthy
save $result\11_status_kesehatan.dta, replace
			



*valuasi asset 
use $induk\b3a_hr1.dta, replace
gen house_land=1  if hr1type =="A"
	replace house_land=0 if house_land==.
	label var house_land " kepemilikan rumah tanah "
	label define house_land 1"punya" 0"tdak punya"
	label value house_land house_land
gen asset_vehiclet=1 if hr1type =="E"
replace asset_vehiclet=0 if asset_vehiclet==.
	label var asset_vehiclet " kepeemilikan kendaraan"
	label define asset_vehiclet 1"punya" 0"tidak memiliki"
	label value asset_vehiclet asset_vehiclet
gen land_nonfarm=1 if hr1type=="C"
replace land_nonfarm=0 if land_nonfarm==.
	label var land_nonfarm "kepemilikan tanah yang non pertanian"
	label define land_nonfarm 1"punya " 0"tida punya"
	label value land_nonfarm land_nonfarm
keep hhid14 house_land asset_vehiclet land_nonfarm
save $result\12_asset.dta, replace






*merger
clear
set more off
capture log close
use  $result\1_jenis_keldll.dta,  clear
merge m:m  hhid14  using $result\2_tempat_tinggal.dta
drop if _merge==2
drop _merge
merge m:m hhid14  using $result\3_panen.dta
drop if _merge==2
drop _merge
merge m:m hhid14 using $result\4_panen.dta,
drop if _merge==2
drop _merge
merge m:m hhid14 using $result\5_nonfarm.dta
drop if _merge==2
drop _merge
merge m:m hhid14 using $result\6_upah.dta
drop if _merge==2
drop _merge 
merge m:m hhid14 using $result\7_hutang.dta
drop if _merge==2
drop _merge 
merge m:m hhid14 using $result\8_status_formal.dta
drop if _merge==2
drop _merge 
merge m:m hhid14 using $result\9_konsum1.dta
drop if _merge==2
drop _merge
merge m:m hhid14 using $result\10_konsum2.dta
drop if _merge==2
drop _merge 
merge m:m hhid14 using $result\11_status_kesehatan.dta
drop if _merge==2
drop _merge 
merge m:m hhid14 using $result\12_asset.dta
drop if _merge==2
drop _merge 

*cleaning data 
*pembersihan dan cleaning data 
	*1.mengisi nilai farm dan nfarm yang missing 
		for var pendapatan expend_food expend_nonfood farm times tnfarm : replace X= 0 if X==.
	*2. membuat total panen
		gen tfarm = times * farm
	*3.menentukan total pendapatan rumah tangga 
		label var tfarm "total pendapatan dari pertanian"
		gen income=tfarm + tnfarm + pendapatan
		format %12.0f income
		label var income "total pendapatan keluarga"		
*debt per income
replace debt= 0 if debt==.
gen debt_perincome=debt/income
	label var debt_perincome " hutang per pendapatan"
	replace debt_perincome= 0 if debt_perincome==.
	format %12.0f debt_perincome
	
	
	keep anak_sekolah age_fath educyr size_family tempat_tinggal farm landfarm times tnfarm pendapatan insti_tolak get_credit debt pekerjaan_formal expend_food expend_nonfood healthy house_land asset_vehiclet land_nonfarm tfarm income
export delimited using "D:\penelitinn\credit_rationing\databro1.csv", nolabel quote replace

	*income
*gen ln_income=ln(income) 
/*expenditur
gen expend_fd=expend_food*4.3
	format %12.0f expend_fd
	format %12.0f expend_nonfood
gen ekpenditure= expend_fd + expend_nonfood
	format %12.0f ekpenditure
/*gen miskin=1 if ekpenditure < 333034
	replace  miskin=0 if miskin==.
	drop if ekpenditure==0
	drop if get_credit==.
	drop if income==0
	
	*/
save $result\data.dta, replace


export delimited using "D:\penelitinn\credit_rationing\databro.csv", nolabel quote replace
keep  in 1/10
export delimited using "D:\penelitinn\credit_rationing\databro1.csv", nolabel quote replace


/*rationing formal 
	logit  get_credit age_fath educyr tempat_tinggal ln_income size_family healthy asset_vehiclet miskin landfarm if pekerjaan_formal==1	
	outreg2 using $result\rationingtheory.doc, replace  ctitle(Formal) 
	quietly logit  get_credit age_fath educyr tempat_tinggal ln_income size_family healthy asset_vehiclet miskin landfarm if pekerjaan_formal==1
	margins, dydx(*)  atmeans post
	outreg2 using $result\rationingtheory.doc, append  ctitle(Marginal effect Formal) 
*rationing informal 	
	logit  get_credit age_fath educyr tempat_tinggal ln_income size_family healthy asset_vehiclet miskin landfarm if pekerjaan_formal==0
	 outreg2 using $result\rationingtheory.doc, append  ctitle(Informal) 
	
	 quietly logit  get_credit age_fath educyr tempat_tinggal ln_income size_family healthy asset_vehiclet miskin landfarm if pekerjaan_formal==0
	margins, dydx(*)  atmeans post
	outreg2 using $result\rationingtheory.doc, append  ctitle(Marginal effect InSformal) 
	
