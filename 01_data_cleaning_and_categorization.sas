proc casutil;
    droptable casdata="final_promoted" incaslib="casuser" quiet;
run;

data casuser.final_analysis_data (replace=yes);
    set casuser.arazi_verisi;
    
    length primary_category $20 tapu_clean $200;
    length temp_aciklama $200 tapu_parcasi $100;
    length mahalle_char $100 tapucinsaciklama_char $200;

    /* ==============================================
    MAHALLE NAME CLEANING - UPDATE ORIGINAL VARIABLE
    ============================================== */
    length mahalle_char $100;
    mahalle_char = strip(compbl(tranwrd(mahalle, "_", " ")));
    mahalle_char = lowcase(mahalle_char);

    
    /* Turkish character replacement */
    mahalle_char = tranwrd(mahalle_char, "ç", "c");
    mahalle_char = tranwrd(mahalle_char, "ğ", "g");
    mahalle_char = tranwrd(mahalle_char, "ı", "i");
    mahalle_char = tranwrd(mahalle_char, "ö", "o");
    mahalle_char = tranwrd(mahalle_char, "ş", "s");
    mahalle_char = tranwrd(mahalle_char, "ü", "u");
    
    /* Update original mahalle variable */
    mahalle = upcase(mahalle_char);

    /* ==============================================
    TAPU DESCRIPTION CLEANING - UPDATE ORIGINAL VARIABLE
    ============================================== */
    tapucinsaciklama_char = strip(put(tapucinsaciklama, $200.));
    tapucinsaciklama_char = lowcase(tapucinsaciklama_char);
    
    /* Turkish character replacement */
    tapucinsaciklama_char = tranwrd(tapucinsaciklama_char, "ç", "c");
    tapucinsaciklama_char = tranwrd(tapucinsaciklama_char, "ğ", "g");
    tapucinsaciklama_char = tranwrd(tapucinsaciklama_char, "ı", "i");
    tapucinsaciklama_char = tranwrd(tapucinsaciklama_char, "ö", "o");
    tapucinsaciklama_char = tranwrd(tapucinsaciklama_char, "ş", "s");
    tapucinsaciklama_char = tranwrd(tapucinsaciklama_char, "ü", "u");
    
    tapucinsaciklama_char = upcase(tapucinsaciklama_char);
    tapucinsaciklama_char = strip(compbl(tapucinsaciklama_char));
    
    /* Remove special characters */
    tapucinsaciklama_char = compress(tapucinsaciklama_char, 
        '.()[]{}:;"''!?-_/\\|@#$%^&*+=~`<>•●●©®™…""''', '');
    
    /* Update original tapucinsaciklama variable */
    tapucinsaciklama = tapucinsaciklama_char;

    /* ==============================================
    LAND USE CATEGORIZATION - 7 CATEGORIES
    ============================================== */
    
    /* Handle multiple categories (separated by comma or "VE") */
    if index(tapucinsaciklama, ',') > 0 or index(tapucinsaciklama, ' VE ') > 0 then do;
        temp_aciklama = tranwrd(tapucinsaciklama, ' VE ', ',');
        tapu_parcasi = strip(scan(temp_aciklama, 1, ','));
        tapu_clean = upcase(strip(tapu_parcasi));
        has_multiple_categories = 1;
    end;
    else do;
        tapu_clean = upcase(strip(tapucinsaciklama));
        has_multiple_categories = 0;
    end;
    
    /* Category classification logic */
    if index(tapu_clean, 'TARLA') > 0 or
       index(tapu_clean, 'BAHCE') > 0 or
       index(tapu_clean, 'TRALA') > 0 or
       index(tapu_clean, 'BAG') > 0 or
       index(tapu_clean, 'MERA') > 0 or
       index(tapu_clean, 'CAYIR') > 0 or
       index(tapu_clean, 'HARMAN') > 0 or
       index(tapu_clean, 'HALI ARAZI') > 0 or
       index(tapu_clean, 'OTLAKIYE') > 0 or
       index(tapu_clean, 'AGIL') > 0 then do;
        primary_category = 'AGRICULTURAL';
    end;
    
    else if index(tapu_clean, 'ARSA') > 0 or
            index(tapu_clean, 'HAM TOPRAK') > 0 or
            index(tapu_clean, 'HAMTOPRAK') > 0 or
            index(tapu_clean, 'HAM ARAZI') > 0 or
            index(tapu_clean, 'FIDANLIK') > 0 or
            index(tapu_clean, 'BOS') > 0 or
            index(tapu_clean, 'TASLIK') > 0 or
            index(tapu_clean, 'KULTUR') > 0 or
            index(tapu_clean, 'ORMAN') > 0 or
            tapu_clean = 'M.ARSA' then do;
        primary_category = 'EMPTY_LAND';
    end;
    
    else if index(tapu_clean, 'EV') > 0 or
            index(tapu_clean, 'APARTMAN') > 0 or
            index(tapu_clean, 'MESKEN') > 0 or
            index(tapu_clean, 'KONUT') > 0 or
            index(tapu_clean, 'GARAJ') > 0 or
            index(tapu_clean, 'BINA') > 0 or
            index(tapu_clean, 'MEYDAN') > 0 or
            index(tapu_clean, 'MUSTEMILAT') > 0 or
            index(tapu_clean, 'LOJMAN') > 0 or
            index(tapu_clean, 'DAIRE') > 0 or
            index(tapu_clean, 'AVLU') > 0 then do;
        primary_category = 'RESIDENTIAL';
    end;
    
    else if index(tapu_clean, 'DUKKAN') > 0 or
            index(tapu_clean, 'MAGAZA') > 0 or
            index(tapu_clean, 'DEPO') > 0 or
            index(tapu_clean, 'ANBAR') > 0 or
            index(tapu_clean, 'OFIS') > 0 or
            index(tapu_clean, 'FABRIKA') > 0 or
            index(tapu_clean, 'IS YERI') > 0 or
            index(tapu_clean, 'OKUL') > 0 or
            index(tapu_clean, 'CAMI') > 0 or
            index(tapu_clean, 'AMBAR') > 0 or
            index(tapu_clean, 'AHIR') > 0 or
            index(tapu_clean, 'SAMANLIK') > 0 or
            index(tapu_clean, 'HANE') > 0 or
            index(tapu_clean, 'BESIHANE') > 0 or
            index(tapu_clean, 'ISYERI') > 0 then do;
        primary_category = 'COMMERCIAL';
    end;
    
    else if index(tapu_clean, 'YOL') > 0 or
            index(tapu_clean, 'DEMIRYOLU') > 0 or
            index(tapu_clean, 'KANAL') > 0 or
            index(tapu_clean, 'DIREK') > 0 or
            index(tapu_clean, 'PILON') > 0 or
            index(tapu_clean, 'TRAFO') > 0 or
            index(tapu_clean, 'CESME') > 0 or
            index(tapu_clean, 'KUYU') > 0 or
            index(tapu_clean, 'PARK') > 0 or
            index(tapu_clean, 'TEMEL') > 0 or
            index(tapu_clean, 'ISTASYON') > 0 or
            index(tapu_clean, 'MEZARLIK') > 0 then do;
        primary_category = 'INFRASTRUCTURE';
    end;
    
    else if index(tapu_clean, 'GOL') > 0 or
            index(tapu_clean, 'SU') > 0 or
            index(tapu_clean, 'DERE') > 0 or
            index(tapu_clean, 'SAZLIK') > 0 or
            index(tapu_clean, 'KAMISLIK') > 0 then do;
        primary_category = 'WATER_RELATED';
    end;
    
    else do;
        primary_category = 'OTHER';
    end;
    
    /* Store complete description */
    complete_tapu_description = tapucinsaciklama;

    /* ==============================================
    CKS DATA PROCESSING
    ============================================== */
    
    /* Fix missing CKS registration values */
    if cks_kaydi_var_mi = . then cks_kaydi_var_mi = 0;
    
    /* Clean CKS products */
    if cks_urunler ne '' and cks_urunler ne '.' then do;
        length clean_cks_products $500;
        clean_cks_products = strip(upcase(cks_urunler));
        clean_cks_products = tranwrd(clean_cks_products, 'Ç', 'C');
        clean_cks_products = tranwrd(clean_cks_products, 'Ğ', 'G');
        clean_cks_products = tranwrd(clean_cks_products, 'İ', 'I');
        clean_cks_products = tranwrd(clean_cks_products, 'Ö', 'O');
        clean_cks_products = tranwrd(clean_cks_products, 'Ş', 'S');
        clean_cks_products = tranwrd(clean_cks_products, 'Ü', 'U');
    end;
    else do;
        clean_cks_products = '';
    end;

    /* ==============================================
    AREA CALCULATIONS AND FLAGS
    ============================================== */
    
    /* Convert area to hectares */
    if A0_Ekilebilir_Arazi ne . and A0_Ekilebilir_Arazi > 0 then 
        area_hectares = A0_Ekilebilir_Arazi / 10000;
    else 
        area_hectares = 0;
    
    /* Agricultural relevance flag */
    is_agricultural_relevant = (primary_category = 'AGRICULTURAL');

    /* ==============================================
    NVDI ANALYSIS - MONTHLY CHANGE DETECTION (RELAXED THRESHOLDS)
    ============================================== */
    
    /* Month-to-month percentage changes */
    if Eyl2023_01Ara2023_median > 0 and Ara2023_01Sub2024_median > 0 then
        ara_change_pct = ((Ara2023_01Sub2024_median - Eyl2023_01Ara2023_median) / Eyl2023_01Ara2023_median) * 100;
    
    if Ara2023_01Sub2024_median > 0 and Sub2024_01Mar2024_median > 0 then
        sub_change_pct = ((Sub2024_01Mar2024_median - Ara2023_01Sub2024_median) / Ara2023_01Sub2024_median) * 100;
    
    if Sub2024_01Mar2024_median > 0 and Mar2024_01Nis2024_median > 0 then
        mar_change_pct = ((Mar2024_01Nis2024_median - Sub2024_01Mar2024_median) / Sub2024_01Mar2024_median) * 100;
    
    if Mar2024_01Nis2024_median > 0 and Nis2024_01May2024_median > 0 then
        nis_change_pct = ((Nis2024_01May2024_median - Mar2024_01Nis2024_median) / Mar2024_01Nis2024_median) * 100;
    
    if Nis2024_01May2024_median > 0 and May2024_01Haz2024_median > 0 then
        may_change_pct = ((May2024_01Haz2024_median - Nis2024_01May2024_median) / Nis2024_01May2024_median) * 100;
    
    if May2024_01Haz2024_median > 0 and Haz2024_01Tem2024_median > 0 then
        haz_change_pct = ((Haz2024_01Tem2024_median - May2024_01Haz2024_median) / May2024_01Haz2024_median) * 100;
    
    /* Count significant monthly increases - RELAXED FROM 60% TO 40% */
    significant_increases = 0;
    if ara_change_pct > 40 then significant_increases + 1;
    if sub_change_pct > 40 then significant_increases + 1;
    if mar_change_pct > 40 then significant_increases + 1;
    if nis_change_pct > 40 then significant_increases + 1;
    if may_change_pct > 40 then significant_increases + 1;
    if haz_change_pct > 40 then significant_increases + 1;
    
    /* Maximum monthly increase */
    max_monthly_increase = max(ara_change_pct, sub_change_pct, mar_change_pct, 
                              nis_change_pct, may_change_pct, haz_change_pct);
    
    /* ==============================================
    PRODUCTION ACTIVITY CLASSIFICATION - RELAXED THRESHOLDS
    ============================================== */
    
    /* Basic requirements - RELAXED */
    adequate_size = (area_hectares >= 0.05);      /* RELAXED: 500m² from 1000m² */
    has_high_nvdi = (max(Eyl2023_01Ara2023_median, Ara2023_01Sub2024_median, 
                        Sub2024_01Mar2024_median, Mar2024_01Nis2024_median,
                        Nis2024_01May2024_median, May2024_01Haz2024_median, 
                        Haz2024_01Tem2024_median) > 30);  /* RELAXED: 30 from 40 */
    
    /* Activity Classification - RELAXED */
    length activity_status $20;
    if adequate_size = 0 or has_high_nvdi = 0 then do;
        activity_status = 'NO_ACTIVITY';
    end;
    else if significant_increases >= 1 or max_monthly_increase > 60 then do;  /* RELAXED: 60 from 80 */
        activity_status = 'SUSPICIOUS';
    end;
    else do;
        activity_status = 'NORMAL';
    end;
    
    /* Production flags */
    has_production = (activity_status in ('SUSPICIOUS', 'NORMAL'));
    has_suspicious_production = (activity_status = 'SUSPICIOUS');

    /* ==============================================
    CKS DECLARATION vs REALITY ANALYSIS
    ============================================== */
    
    /* CKS declaration status */
    length cks_beyan_status $20;
    if cks_kaydi_var_mi = 1 then do;
        if clean_cks_products = '' or clean_cks_products = '.' then 
            cks_beyan_status = 'NO_DECLARATION';
        else if index(upcase(clean_cks_products), 'NADAS') > 0 then 
            cks_beyan_status = 'FALLOW_DECLARED';
        else 
            cks_beyan_status = 'PRODUCTION_DECLARED';
    end;
    else do;
        cks_beyan_status = 'NOT_REGISTERED';
    end;
    
    /* Inconsistency detection */
    length inconsistency_flag $40;
    if cks_beyan_status = 'PRODUCTION_DECLARED' and activity_status = 'NO_ACTIVITY' then
        inconsistency_flag = 'DECLARED_BUT_NO_PRODUCTION';
    else if cks_beyan_status = 'PRODUCTION_DECLARED' and activity_status = 'SUSPICIOUS' then
        inconsistency_flag = 'SUSPICIOUS_PATTERN_DESPITE_REGISTRATION';
    else if cks_beyan_status = 'NOT_REGISTERED' and has_production = 1 then
        inconsistency_flag = 'UNREGISTERED_PRODUCTION';
    else if cks_beyan_status = 'PRODUCTION_DECLARED' and activity_status = 'NORMAL' then
        inconsistency_flag = 'CONSISTENT_PRODUCTION';
    else if cks_beyan_status = 'FALLOW_DECLARED' and activity_status = 'NO_ACTIVITY' then
        inconsistency_flag = 'CONSISTENT_FALLOW';
    else
        inconsistency_flag = 'OTHER';
    
    /* Problem flags for dashboard */
    false_declaration = (inconsistency_flag = 'DECLARED_BUT_NO_PRODUCTION');
    unregistered_production = (inconsistency_flag = 'UNREGISTERED_PRODUCTION');
    suspicious_registered = (inconsistency_flag = 'SUSPICIOUS_PATTERN_DESPITE_REGISTRATION');

    /* ==============================================
    DASHBOARD VARIABLES
    ============================================== */
    
    /* Production flags for dashboard */
    has_production_activity = (activity_status in ('SUSPICIOUS', 'NORMAL'));
    
    /* Dashboard specific combinations */
    cks_registered_with_production = (cks_kaydi_var_mi = 1 and has_production_activity = 1);
    cks_registered_without_prod = (cks_kaydi_var_mi = 1 and has_production_activity = 0);
    cks_unregistered_with_production = (cks_kaydi_var_mi = 0 and has_production_activity = 1);
    cks_unregistered_without_prod = (cks_kaydi_var_mi = 0 and has_production_activity = 0);
    
    /* CKS Status - Clear labels */
    length cks_status $20;
    if cks_kaydi_var_mi = 1 then cks_status = 1;
    else cks_status = 0;
    
    /* Production Status - Clear labels */
    length production_status $20;
    if has_production_activity = 1 then production_status = 'Production Detected';
    else production_status = 'No Production';
    
    /* Combined Status for detailed analysis */
    length combined_status $40;
    if cks_kaydi_var_mi = 1 and has_production_activity = 1 then 
        combined_status = 'CKS Registered + Production';
    else if cks_kaydi_var_mi = 1 and has_production_activity = 0 then 
        combined_status = 'CKS Registered + No Production';
    else if cks_kaydi_var_mi = 0 and has_production_activity = 1 then 
        combined_status = 'CKS Unregistered + Production';
    else 
        combined_status = 'CKS Unregistered + No Production';
    
    /* Size categories */
    length size_category $20;
    if area_hectares = 0 then size_category = 'No Area Data';
    else if area_hectares <= 0.5 then size_category = 'Small (<=0.5 ha)';
    else if area_hectares <= 2 then size_category = 'Medium (0.5-2 ha)';
    else size_category = 'Large (>2 ha)';
    
    /* Drop temporary variables */
    drop mahalle_char tapucinsaciklama_char tapu_clean temp_aciklama tapu_parcasi;
    
    /* Variable labels */
    label
        mahalle = "Neighborhood Name (Cleaned)"
        tapucinsaciklama = "Tapu Description (Cleaned)"
        primary_category = "Primary Land Use Category"
        complete_tapu_description = "Complete Tapu Description"
        has_multiple_categories = "Has Multiple Land Use Categories"
        clean_cks_products = "Cleaned CKS Products"
        area_hectares = "Area in Hectares"
        is_agricultural_relevant = "Agricultural Relevance Flag"
        activity_status = "Production Activity Status"
        cks_beyan_status = "CKS Declaration Status"
        inconsistency_flag = "CKS vs NVDI Inconsistency Type"
        has_production = "Has Any Production Activity"
        has_suspicious_production = "Has Suspicious Production Activity"
        max_monthly_increase = "Maximum Monthly NVDI Increase (%)"
        significant_increases = "Count of Significant Monthly Increases"
        false_declaration = "False Production Declaration"
        unregistered_production = "Unregistered Production"
        suspicious_registered = "Suspicious Pattern Despite Registration"
        has_production_activity = "Production Activity Detected"
        cks_registered_with_production = "CKS Registered with Production"
        cks_registered_without_prod = "CKS Registered without Production"
        cks_unregistered_with_production = "CKS Unregistered with Production"
        cks_unregistered_without_prod = "CKS Unregistered without Production"
        cks_status = "CKS Registration Status"
        production_status = "Production Detection Status"
        combined_status = "CKS and Production Combined Status"
        size_category = "Parcel Size Category";
run;

/* ==============================================
QUALITY CHECK REPORTS
============================================== */

/* Check unique neighborhoods count */
proc sql;
    select count(distinct mahalle) as unique_mahalle_count
    from casuser.final_analysis_data;
    title "Unique Neighborhood Count After Cleaning";
quit;

/* Dashboard summary statistics */
proc sql;
    select 
        count(*) as total_parcels,
        
        /* Basic counts */
        sum(case when cks_kaydi_var_mi = 1 then 1 else 0 end) as cks_registered_count,
        sum(case when cks_kaydi_var_mi = 0 then 1 else 0 end) as cks_unregistered_count,
        
        /* Production combinations */
        sum(cks_registered_with_production) as cks_reg_with_prod,
        sum(cks_registered_without_prod) as cks_reg_without_prod,
        sum(cks_unregistered_with_production) as cks_unreg_with_prod,
        sum(cks_unregistered_without_prod) as cks_unreg_without_prod,
        
        /* Key percentages for dashboard */
        calculated cks_reg_with_prod / calculated cks_registered_count * 100 as pct_cks_registered_producing format=5.1,
        calculated cks_unreg_with_prod / calculated cks_unregistered_count * 100 as pct_cks_unregistered_producing format=5.1,
        calculated cks_registered_count / calculated total_parcels * 100 as pct_cks_registered format=5.1
        
    from casuser.final_analysis_data;
    title "Dashboard Summary Statistics";
quit;

/* Activity status distribution */
proc freq data=casuser.final_analysis_data;
    tables activity_status * cks_status;
    title "Production Activity by CKS Status";
run;

/* Combined status summary */
proc freq data=casuser.final_analysis_data;
    tables combined_status;
    title "Combined CKS and Production Status";
run;

/* ==============================================
PROMOTE FINAL DATASET
============================================== */

proc casutil;
    promote casdata="final_analysis_data" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="final_promoted";
run;

%put Final dataset ready: final_analysis_promoted;
%put Use this single dataset in VA for your executive dashboard;