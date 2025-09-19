/* ==============================================
UNREGISTERED PARCEL CATEGORIZATION FOR MODEL SCORING
Input: unregistered_parcels_promoted from 02_unregistered_parcels_analysis.sas
Adds category features to unregistered parcels for model scoring
============================================== */

/* ==============================================
CLEANUP AND PREPARATION
============================================== */

proc casutil;
    droptable casdata="unreg_model_ready" incaslib="casuser" quiet;
    droptable casdata="unreg_summary" incaslib="casuser" quiet;
run;

/* ==============================================
UNREGISTERED PARCEL CATEGORIZATION
Input: unregistered_parcels_promoted (CKS unregistered parcels)
============================================== */

data casuser.unregistered_model_ready;
    set casuser.unregistered_parcels_promoted;
    
    /* Initialize category flags - CAS compatible numeric length */
    length dominant_category $20 secondary_category $20;
    length has_tahil has_baklagil has_yagli_tohum has_sebze has_meyve has_yemlik has_nadas has_endustriyel 8;
    length category_count mixed_category_flag economic_diversity_score 8;
    length seasonal_pattern $15 water_need_level $10 economic_category $10;
    length is_monoculture is_diversified has_high_value_crops is_subsistence_farming is_commercial_farming 8;
    
    /* Initialize all flags to 0 - NO PRODUCTS FOR UNREGISTERED */
    has_tahil = 0; has_baklagil = 0; has_yagli_tohum = 0; has_sebze = 0;
    has_meyve = 0; has_yemlik = 0; has_nadas = 0; has_endustriyel = 0;
    category_count = 0;
    economic_diversity_score = 0;
    mixed_category_flag = 0;
    is_monoculture = 0; is_diversified = 0; has_high_value_crops = 0;
    is_subsistence_farming = 0; is_commercial_farming = 0;
    
    /* ==============================================
    NO PRODUCT CATEGORIZATION FOR UNREGISTERED
    ============================================== */
    
    /* Since unregistered parcels have no product declarations */
    dominant_category = 'NO_PRODUCTS';
    secondary_category = 'NONE';
    
    /* ==============================================
    DERIVED CATEGORICAL FEATURES FOR MODELING
    ============================================== */
    
    /* Mixed category flag */
    mixed_category_flag = 0; /* No products = no mixing */
    
    /* Seasonal pattern - unknown for unregistered */
    seasonal_pattern = 'UNKNOWN';
    
    /* Water requirement level - unknown */
    water_need_level = 'UNKNOWN';
    
    /* Economic value category - none declared */
    economic_category = 'UNKNOWN';
    
    /* ==============================================
    MODEL-READY FLAGS
    ============================================== */
    
    /* Binary flags for specific model features - all 0 for unregistered */
    is_monoculture = 0;
    is_diversified = 0;
    has_high_value_crops = 0;
    is_subsistence_farming = 0;
    is_commercial_farming = 0;
    
    /* ==============================================
    CATEGORICAL VERSIONS FOR MODEL STUDIO
    ============================================== */
    
    /* Create categorical versions of binary flags */
    length has_tahil_cat has_baklagil_cat has_yagli_tohum_cat has_sebze_cat $3;
    length has_meyve_cat has_yemlik_cat has_nadas_cat has_endustriyel_cat $3;
    length mixed_category_cat is_monoculture_cat is_diversified_cat $3;
    length has_high_value_cat is_commercial_cat is_subsistence_cat $3;
    length has_suspicious_prod_cat false_declaration_cat unregistered_prod_cat $3;
    
    /* All categorical versions are 'NO' for unregistered parcels */
    has_tahil_cat = 'NO'; has_baklagil_cat = 'NO'; has_yagli_tohum_cat = 'NO'; 
    has_sebze_cat = 'NO'; has_meyve_cat = 'NO'; has_yemlik_cat = 'NO'; 
    has_nadas_cat = 'NO'; has_endustriyel_cat = 'NO';
    
    mixed_category_cat = 'NO'; is_monoculture_cat = 'NO'; is_diversified_cat = 'NO';
    has_high_value_cat = 'NO'; is_commercial_cat = 'NO'; is_subsistence_cat = 'NO';
    
    /* Analysis flags - for unregistered parcels */
    if has_suspicious_production = 1 then has_suspicious_prod_cat = 'YES'; else has_suspicious_prod_cat = 'NO';
    if false_declaration = 1 then false_declaration_cat = 'YES'; else false_declaration_cat = 'NO';
    if unregistered_production = 1 then unregistered_prod_cat = 'YES'; else unregistered_prod_cat = 'NO';
    
    /* Labels */
    label
        dominant_category = "Dominant Product Category"
        secondary_category = "Secondary Product Category"
        has_tahil = "Has Grain Crops"
        has_baklagil = "Has Legume Crops"
        has_yagli_tohum = "Has Oilseed Crops"
        has_sebze = "Has Vegetable Crops"
        has_meyve = "Has Fruit Crops"
        has_yemlik = "Has Forage Crops"
        has_nadas = "Has Fallow"
        has_endustriyel = "Has Industrial Crops"
        category_count = "Number of Different Crop Categories"
        mixed_category_flag = "Mixed Category Parcel"
        economic_diversity_score = "Economic Diversity Score"
        seasonal_pattern = "Seasonal Growing Pattern"
        water_need_level = "Water Requirement Level"
        economic_category = "Economic Value Category"
        is_monoculture = "Monoculture Farming"
        is_diversified = "Diversified Farming (3+ categories)"
        has_high_value_crops = "Has High-Value Crops"
        is_subsistence_farming = "Subsistence Farming Pattern"
        is_commercial_farming = "Commercial Farming Pattern"
        /* Categorical versions */
        has_tahil_cat = "Has Grain Crops (Categorical)"
        has_baklagil_cat = "Has Legume Crops (Categorical)"
        has_yagli_tohum_cat = "Has Oilseed Crops (Categorical)"
        has_sebze_cat = "Has Vegetable Crops (Categorical)"
        has_meyve_cat = "Has Fruit Crops (Categorical)"
        has_yemlik_cat = "Has Forage Crops (Categorical)"
        has_nadas_cat = "Has Fallow (Categorical)"
        has_endustriyel_cat = "Has Industrial Crops (Categorical)"
        mixed_category_cat = "Mixed Category Parcel (Categorical)"
        is_monoculture_cat = "Monoculture Farming (Categorical)"
        is_diversified_cat = "Diversified Farming (Categorical)"
        has_high_value_cat = "Has High-Value Crops (Categorical)"
        is_commercial_cat = "Commercial Farming (Categorical)"
        is_subsistence_cat = "Subsistence Farming (Categorical)"
        has_suspicious_prod_cat = "Has Suspicious Production (Categorical)"
        false_declaration_cat = "False Declaration (Categorical)"
        unregistered_prod_cat = "Unregistered Production (Categorical)";
    
    /* Keep ALL variables - no drops needed */
run;

/* ==============================================
CREATE SUMMARY STATISTICS
============================================== */

proc summary data=casuser.unregistered_model_ready nway;
    class dominant_category;
    var area_hectares economic_diversity_score category_count;
    output out=casuser.unregistered_summary
        n=parcel_count
        mean(area_hectares)=avg_area
        sum(area_hectares)=total_area
        mean(economic_diversity_score)=avg_economic_score
        mean(category_count)=avg_category_count;
run;

data casuser.unregistered_summary;
    set casuser.unregistered_summary;
    drop _type_ _freq_;
run;

/* ==============================================
PROMOTE TABLES FOR MODEL SCORING
============================================== */

proc casutil;
    /* Promote model-ready dataset - SHORTER NAME */
    promote casdata="unregistered_model_ready" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="unreg_model_ready";
    
    /* Promote summary statistics */
    promote casdata="unregistered_summary" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="unreg_summary";
run;

/* ==============================================
VERIFICATION REPORTS - FIXED FOR CAS
============================================== */

/* 1. Record count verification - use promoted table */
proc casutil;
    contents casdata="unreg_model_ready" incaslib="casuser";
run;

/* 2. Quick check with SQL */
proc sql;
    select count(*) as unregistered_count
    from casuser.unreg_model_ready;
    title "Unregistered Parcels Ready for Scoring";
quit;

/* ==============================================
CLEANUP TEMPORARY TABLES - KEEP PROMOTED
============================================== */

proc casutil;
    droptable casdata="unregistered_model_ready" incaslib="casuser" quiet;
    droptable casdata="unregistered_summary" incaslib="casuser" quiet;
run;

/* ==============================================
FINAL STATUS
============================================== */

%put ===============================================;
%put UNREGISTERED PARCEL CATEGORIZATION COMPLETED;
%put ===============================================;
%put Model-ready table: unreg_model_ready;
%put Features added for unregistered parcels:;
%put - All product categories set to NO/0;
%put - Dominant category: NO_PRODUCTS;
%put - Same structure as registered parcels;
%put - Ready for model scoring;
%put ===============================================;
%put Use unreg_model_ready in Score Data component;
%put ===============================================;