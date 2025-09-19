/* ==============================================
ISOLATE 44K SUSPECTED PRODUCTION PARCELS
Input: scoring_analysis_promoted from 06_scoring_results_analysis.sas
Output: Clean dataset for crop prediction model
============================================== */

/* ==============================================
CLEANUP AND PREPARATION
============================================== */

proc casutil;
    droptable casdata="suspected_44k_promoted" incaslib="casuser" quiet;
    droptable casdata="crop_training_data_promoted" incaslib="casuser" quiet;
run;

/* ==============================================
ISOLATE 44K SUSPECTED PARCELS
Filter: EM_CLASSIFICATION = 1 (predicted production)
============================================== */

data casuser.suspected_44k;
    set casuser.scoring_analysis_promoted;
    
    /* Only parcels with predicted production - TEXT VALUE */
    if EM_CLASSIFICATION = "Production Detected";
    
    /* Create confidence categories for analysis */
    length confidence_level $10;
    if EM_EVENTPROBABILITY >= 0.8 then confidence_level = 'VERY_HIGH';
    else if EM_EVENTPROBABILITY >= 0.6 then confidence_level = 'HIGH';
    else if EM_EVENTPROBABILITY >= 0.5 then confidence_level = 'MEDIUM';
    else confidence_level = 'LOW';
    
    /* Flag for model readiness */
    model_ready = 1;
    
    /* Keep all variables */
    
    label
        confidence_level = "Prediction Confidence Level"
        model_ready = "Ready for Crop Prediction Model";
run;

/* ==============================================
CREATE CROP TRAINING DATA
Filter CKS registered with valid product declarations and confirmed production
============================================== */

data casuser.crop_training_data;
    set casuser.parcel_model_ready_promoted;
    
    /* Training criteria: */
    /* 1. CKS registered */
    /* 2. Has valid product list */
    /* 3. NVDI confirms production (NORMAL or SUSPICIOUS activity) */
    if cks_kaydi_var_mi = 1 and 
       product_list_clean ne '' and 
       product_list_clean ne '.' and
       activity_status in ('NORMAL', 'SUSPICIOUS') and
       dominant_category ne 'NADAS' and
       dominant_category ne 'DIGER';
    
    /* Create target variable for crop prediction - FILTERED PRODUCTS */
    length crop_target $30;
    
    /* Use specific product from product_list_clean - ONLY COMMON PRODUCTS */
    if product_list_clean ne '' and product_list_clean ne '.' then do;
        /* Get first product from the list */
        temp_crop = strip(scan(product_list_clean, 1, ','));
        
        /* Only keep products with sufficient training data (20+ samples) */
        if temp_crop in ('BUGDAY', 'ARPA', 'SOGAN', 'MISIR', 'NOHUT', 'NADAS', 'YONCA', 
                        'AYCICEGI', 'SILAJLIK MISIR', 'YULAF', 'DOMATES', 'CEVIZ', 
                        'KABAK', 'BIBER', 'PATATES', 'SEKER PANCARI') then do;
            crop_target = temp_crop;
        end;
        else do;
            /* Skip rare products */
            delete;
        end;
    end;
    else do;
        /* If no products, skip this record */
        delete;
    end;
    
    /* Training flag */
    is_training_data = 1;
    
    label
        crop_target = "Target Crop Category for Model"
        is_training_data = "Training Data Flag";
run;

/* ==============================================
VERIFICATION AND STATISTICS
============================================== */

/* 1. Count verification */
proc sql;
    select count(*) as suspected_count
    from casuser.suspected_44k;
    title "Suspected Production Parcels Count";
quit;

proc sql;
    select count(*) as training_count
    from casuser.crop_training_data;
    title "Crop Training Data Count";
quit;

/* 2. Confidence distribution */
proc freq data=casuser.suspected_44k;
    tables confidence_level;
    title "Confidence Level Distribution - 44K Suspected";
run;

/* 3. Training data crop distribution */
proc freq data=casuser.crop_training_data;
    tables crop_target;
    title "Crop Distribution in Training Data";
run;

/* 4. Key statistics */
proc means data=casuser.suspected_44k n mean std min max;
    var EM_EVENTPROBABILITY area_hectares;
    title "Key Statistics - 44K Suspected Parcels";
run;

proc means data=casuser.crop_training_data n mean std;
    var area_hectares category_count economic_diversity_score;
    title "Training Data Statistics";
run;

/* ==============================================
PROMOTE TABLES FOR MODEL STUDIO
============================================== */

proc casutil;
    /* Promote 44K suspected parcels */
    promote casdata="suspected_44k" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="suspected_44k_promoted";
    
    /* Promote crop training data */
    promote casdata="crop_training_data" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="crop_training_data_promoted";
run;

/* ==============================================
DATA QUALITY CHECKS
============================================== */

/* 1. Missing NVDI data check */
proc means data=casuser.suspected_44k_promoted n nmiss;
    var Eyl2023_01Ara2023_median Ara2023_01Sub2024_median 
        Mar2024_01Nis2024_median Nis2024_01May2024_median
        max_monthly_increase;
    title "Missing NVDI Data Check - 44K Suspected";
run;

proc means data=casuser.crop_training_data_promoted n nmiss;
    var Eyl2023_01Ara2023_median Ara2023_01Sub2024_median 
        Mar2024_01Nis2024_median Nis2024_01May2024_median
        max_monthly_increase;
    title "Missing NVDI Data Check - Training Data";
run;

/* 2. Feature availability check */
proc sql;
    select 
        'FEATURE_CHECK' as check_type,
        count(*) as total_records,
        sum(case when area_hectares > 0 then 1 else 0 end) as has_area,
        sum(case when mahalle ne '' then 1 else 0 end) as has_mahalle,
        sum(case when max_monthly_increase is not null then 1 else 0 end) as has_nvdi_change
    from casuser.suspected_44k_promoted;
    title "Feature Availability - 44K Suspected";
quit;

/* ==============================================
NEIGHBORHOOD ANALYSIS FOR 44K
============================================== */

proc summary data=casuser.suspected_44k_promoted nway;
    class mahalle;
    var EM_EVENTPROBABILITY area_hectares;
    output out=casuser.mahalle_44k_summary
        n=suspected_count_in_mahalle
        mean(EM_EVENTPROBABILITY)=avg_confidence
        sum(area_hectares)=total_suspected_area;
run;

proc print data=casuser.mahalle_44k_summary (obs=15);
    var mahalle suspected_count_in_mahalle avg_confidence total_suspected_area;
    title "Top 15 Neighborhoods by Suspected Parcel Count";
run;

/* ==============================================
CLEANUP TEMPORARY TABLES
============================================== */

proc casutil;
    droptable casdata="suspected_44k" incaslib="casuser" quiet;
    droptable casdata="crop_training_data" incaslib="casuser" quiet;
    droptable casdata="mahalle_44k_summary" incaslib="casuser" quiet;
run;

/* ==============================================
FINAL STATUS
============================================== */

%put ===============================================;
%put 44K SUSPECTED PARCELS ISOLATION COMPLETED;
%put ===============================================;
%put Tables ready for crop prediction model:;
%put 1. suspected_44k_promoted - 44K parcels for scoring;
%put 2. crop_training_data_promoted - Training data for model;
%put ===============================================;
%put Next steps:;
%put - Create new Model Studio project;
%put - Use crop_training_data_promoted for training;
%put - Target variable: crop_target;
%put - Score suspected_44k_promoted for crop prediction;
%put ===============================================;

/* Check crop target distribution */
proc freq data=casuser.crop_training_data_promoted;
    tables crop_target;
    title "Crop Target Distribution for Training";
run;