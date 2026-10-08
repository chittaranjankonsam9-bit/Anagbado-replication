Research method replication presentation


version 17.0
clear all
set more off


 1. DATA IMPORT

cd "C:\Users\misek\Downloads\OneDrive"

pwd

import excel "Complete_Data_main 1.xls", firstrow clear

describe

 2. VARIABLE CONSTRUCTION

Scale energy efficiency
gen ety_m = ety * 1000000000

Encode identifiers
encode country, gen(country_id)
encode countrycode, gen(new_countrycode)

Panel structure
xtset country_id year

 Logs and transformations
gen log_gdp = log(gdp)
gen log_ecpi = asinh(ecpi)
gen log_ety2 = ln(ety_m)
gen log_egc = log(egc)
gen log_ety = log(ety)

log of other variables
gen log_gf = log(gf)
gen log_pop = log(pop)
gen log_ety = log(ety)

 First differences
gen diff_log_ety = D.log_ety
gen diff_log_gdp = D.log_gdp
gen diff_log_ecpi = D.log_ecpi
gen diff_log_egc = D.log_egc


 Correlations
pwcorr log_ety log_gdp log_ecpi, sig
corr log_ety2 log_gdp log_ecpi 


xtsum log_gdp log_ety2 log_ecpi, 
xtsum gdp ety_m ecpi, 

summarize ety_m gdp ecpi, detail

Drop missing values for dynamics
drop if missing(diff_log_ety) | missing(diff_log_gdp) | missing(diff_log_ecpi)| missing(diff_log_egc)



 4. TIME-SERIES PLOTS


xtline log_ety2
xtline log_gdp
xtline log_ecpi
xtline log_ety, title("Energy Efficiency (Log)")

xtline diff_log_gdp, byopts(title(Growth Rate of GDP))
xtline diff_log_ety, byopts(title(Growth Rate of ety))
xtline diff_log_ecpi, byopts(title(Growth Rate of ecpi))



 5. CROSS-SECTIONAL DEPENDENCE

xtcd log_ety
xtcd log_gdp
xtcd log_ecpi
xtcd log_ety log_gdp log_ecpi
xtcd2 log_ety log_gdp log_ecpi



 6. LAG SELECTION USING COUNTRY-SPECIFIC ARDL


gen lag_gdp_1 = .
gen lag_ety_1 = .
gen lag_ecpi_1 = .

forval i = 1/28 {
    ardl log_gdp log_ety log_ecpi if country_id == `i', maxlags(2 2 2)
    matrix lags = e(lags)
    replace lag_gdp = lags[1, 1] if country_id == `i'
    replace lag_ety = lags[1, 2] if country_id == `i'
    replace lag_ecpi = lags[1, 3] if country_id == `i'

}

Calculate the mode for each lag variable
tab lag_gdp, matcell(freq_gdp)
tab lag_ety, matcell(freq_ety)
tab lag_ecpi, matcell(freq_ecpi)

 Display the most common lag
di "Most common lag for lag_gdp:  " freq_gdp[1,1]
di "Most common lag for lag_ety:  " freq_ety[1,1]
di "Most common lag for lag_ecpi: " freq_ecpi[1,1]

di "Lag_ety modal value: 0"
di "Lag_gdp modal value: 1"
di "Lag_ecpi modal value: 0"

 7. PANEL UNIT ROOT TESTS


 IPS with demeaning
xtunitroot ips log_ety, demean
xtunitroot ips log_gdp, demean
xtunitroot ips log_ecpi, demean
xtunitroot ips diff_log_ety, demean
xtunitroot ips diff_log_gdp, demean
xtunitroot ips diff_log_ecpi, demean

 Cross-sectionally augmented IPS
xtcips log_ety, maxlags(1) bglags(1)
xtcips log_gdp, maxlags(1) bglags(1)
xtcips log_ecpi, maxlags(1) bglags(1)
xtcips diff_log_ety, maxlags(1) bglags(1)
xtcips diff_log_gdp, maxlags(1) bglags(1)
xtcips diff_log_ecpi, maxlags(1) bglags(1)


8. COINTEGRATION TESTS (FULL SAMPLE)

Pedroni
xtcointtest pedroni log_gdp log_ety log_ecpi

Westerlund
xtcointtest westerlund log_gdp log_ety log_ecpi, trend somepanels demean


 9. CLUSTER GROUPS (STRUCTURAL CLUSTERS)


gen cluster_group = .

Group 1: High Efficiency and Wealth
replace cluster_group = 1 if inlist(country, ///
    "Cabo Verde", "Ghana", "Kenya", "Maldives", "Senegal", "Zambia")

Group 2: Resource-Rich
replace cluster_group = 2 if inlist(country, ///
    "Cameroon", "Congo", "Côte d'Ivoire", "Guinea", "Honduras", "Kyrgyzstan")

Group 3: Lower Efficiency (Limited Technology) and Limited Wealth
replace cluster_group = 3 if inlist(country, ///
    "Benin", "Burkina Faso", "Burundi", "Chad", "Mali", "Mozambique", "Togo", "Lesotho")

Group 4: Small Island or Unique Economies or geographically specific characteristics
replace cluster_group = 4 if inlist(country, ///
    "Ethiopia", "Myanmar", "Nepal", "Grenada", "Saint Lucia", "St. Vincent and the Grenadines", ///
    "Tajikistan", "Tonga")

list country cluster_group, sepby(cluster_group)
tabulate cluster_group

	
10. ILLUSTRATIVE GRAPH: ENERGY USE AND GDP PER CAPITA


bys country: gen egc_index = egc / egc[1] * 100
bys country: gen gdpp_index = gdp / gdp[1] * 100


twoway ///
(line egc_index gdpp_index if country=="Ghana", lcolor(blue) lwidth(medthick)) ///
(line egc_index gdpp_index if country=="Honduras", lcolor(orange) lwidth(medthick)) ///
(line egc_index gdpp_index if country=="Chad", lcolor(green) lwidth(medthick)) ///
(line egc_index gdpp_index if country=="Grenada", lcolor(red) lwidth(medthick)), ///
title("Energy Consumption and GDP per Capita Growth (1990–2016)", size(medlarge)) ///
subtitle("Indexed to 1990 = 100", size(small)) ///
xtitle("GDP per Capita Index") ///
ytitle("Energy Consumption Index") ///
legend(order(1 "Ghana" 2 "Honduras" 3 "Chad" 4 "Grenada") ///
       col(1) pos(11) ring(0) region(lstyle(none) color(white))) ///
xlabel(100(25)200, grid) ///
ylabel(100(50)250, grid) ///
xscale(range(100 200)) ///
yscale(range(100 250)) ///
scheme(s2color) graphregion(color(white)) plotregion(lcolor(white))


11. DESCRIPTIVE STATISTICS BY CLUSTER

bysort cluster_group: xtsum log_gdp log_ety2 log_ecpi, 

Set the panel structure
xtset country_id year


12. UNIT ROOT TESTS BY CLUSTER
levelsof cluster_group, local(clusters) 

foreach i of local clusters {
    preserve
    keep if cluster_group == `i'
    
    xtunitroot ips log_ety, demean
    xtunitroot ips log_gdp, demean
    xtunitroot ips log_ecpi, demean
    xtunitroot ips diff_log_ety, demean
    xtunitroot ips diff_log_gdp, demean
    xtunitroot ips diff_log_ecpi, demean

    restore
}

levelsof cluster_group, local(clusters) 

foreach i of local clusters {
    preserve
    keep if cluster_group == `i'
    
    xtcips log_ety, maxlags(1) bglags(1)
    xtcips log_gdp, maxlags(1) bglags(1)
    xtcips log_ecpi, maxlags(1) bglags(1)
    xtcips diff_log_ety, maxlags(1) bglags(1)
    xtcips diff_log_gdp, maxlags(1) bglags(1)
    xtcips diff_log_ecpi, maxlags(1) bglags(1)

    restore
}



 13. COINTEGRATION BY CLUSTER

levelsof cluster_group, local(clusters)

foreach i of local clusters {
    preserve
    keep if cluster_group == `i'
    
    display "Running Pedroni test for cluster group `i'..."
xtcointtest pedroni log_gdp log_ety log_ecpi    
    restore
}


levelsof cluster_group, local(clusters)

foreach i of local clusters {
    preserve
    keep if cluster_group == `i'
    
    display "Running Westerlund test for cluster group `i'..."
xtcointtest westerlund log_gdp log_ety log_ecpi, trend somepanels demean
    restore
}


14. CROSS-SECTIONAL AVERAGES

egen csavg_log_ety = mean(log_ety), by(year)
egen csavg_log_gdp = mean(log_gdp), by(year)
egen csavg_log_ecpi = mean(log_ecpi), by(year)
egen csavg_log_egc = mean(log_egc), by(year)


15. BASELINE PMG ESTIMATION (FULL SAMPLE)


outreg2 using "C:\Users\misek\Downloads\OneDrive" replace

xtpmg d.log_gdp d.log_ety2 d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi, lr(log_gdp log_ety2  log_ecpi) replace pmg 
xtpmg d.log_gdp d.log_ety2 d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi, lr(log_gdp log_ety2  log_ecpi) replace dfe 
hausman pmg DFE, sigmamore

16. CLUSTER-SPECIFIC PMG ESTIMATION


preserve
keep if cluster_group == 1
xtpmg d.log_gdp d.log_ety d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi, lr(log_gdp log_ety log_ecpi) replace pmg
outreg2 using "C:\Users\misek\Downloads\OneDrive" , append
restore


preserve
keep if cluster_group == 3
xtpmg d.log_gdp d.log_ety d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi, lr(log_gdp log_ety  log_ecpi) replace pmg
outreg2 using "C:\Users\misek\Downloads\OneDrive", append
restore


preserve
keep if cluster_group == 4
xtpmg d.log_gdp d.log_ety2 d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi, lr(log_gdp log_ety2  log_ecpi) replace pmg 
restore
outreg2 using "C:\Users\misek\Downloads\OneDrive", append
shell open "C:\Users\misek\Downloads\OneDrive"

preserve
keep if cluster_group == 2
xtpmg d.log_gdp d.log_ety d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi, lr(log_gdp log_ety log_ecpi) replace pmg
outreg2 using "C:\Users\misek\Downloads\OneDrive", append
restore


 17. ROBUSTNESS: RECLUSTERING BY PER-CAPITA ENERGY USE


Per-capita energy use

gen egc_pc = egc / pop
bys country: egen avg_egc_pc = mean(egc_pc)
egen z_avg_egc_pc = std(avg_egc_pc)

cluster kmeans z_avg_egc_pc, k(3) name(engroups)

rename engroups energy_group
tab energy_group

xtset country_id year

xtpmg d.log_gdp d.log_ety2 d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi if energy_group == 1, lr(log_gdp log_ety2 log_ecpi) pmg replace

xtpmg d.log_gdp d.log_ety2 d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi if energy_group == 2, lr(log_gdp log_ety2 log_ecpi) pmg replace

xtpmg d.log_gdp d.log_ety2 d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi if energy_group == 3, lr(log_gdp log_ety2 log_ecpi) pmg replace




 18. ROBUSTNESS: SYSTEM GMM


xtabond2 log_gdp L.log_gdp log_ety2 log_ecpi, gmm(L.log_gdp log_ety2, lag(2 2) collapse) iv(i.year, eq(level)) twostep robust small



19. ROBUSTNESS: ENERGY MIX FROM DIFFERENT SOURCES

Convert percentages to proportions 
gen er_prop   = er/100
gen eogc_prop = eogc/100

 Logs only for positive values
gen ln_er = .
replace ln_er = ln(er_prop) if er_prop > 0

gen ln_eogc = .
replace ln_eogc = ln(eogc_prop) if eogc_prop > 0

 Differences
gen d_ln_er   = d.ln_er
gen d_ln_eogc = d.ln_eogc

drop if missing(d_ln_er) | missing(d_ln_eogc) 

Cross-sectional averages
bys year: egen csavg_ln_er   = mean(ln_er)
bys year: egen csavg_ln_eogc = mean(ln_eogc)

xtset country_id year

xtpmg d.log_gdp d.log_ety2 d.log_ecpi csavg_log_ety csavg_log_gdp csavg_log_ecpi if country=="Cameroon" | country=="Congo" | country=="Côte d'Ivoire" | country=="Ethiopia" | country=="Kenya" | country=="Kyrgyzstan" | country=="Mozambique" | country=="Myanmar" | country=="Nepal" | country=="Senegal" | country=="Tajikistan" | country=="Zambia" | country=="Ghana", lr(log_gdp log_ety2 log_ecpi) pmg replace

xtpmg d.log_gdp d.log_ety2 d.log_ecpi d.ln_er d.ln_eogc csavg_log_ety csavg_log_gdp csavg_log_ecpi csavg_ln_er csavg_ln_eogc if country=="Cameroon" | country=="Congo" | country=="Côte d'Ivoire" | country=="Ethiopia" | country=="Kenya" | country=="Kyrgyzstan" | country=="Mozambique" | country=="Myanmar" | country=="Nepal" | country=="Senegal" | country=="Tajikistan" | country=="Zambia" | country=="Ghana", lr(log_gdp log_ety2 log_ecpi ln_er ln_eogc) pmg replace


END OF DO-FILE
