/* ==============================================
CKS UNREGISTERED PARCELS ANALYSIS FOR SCORING
Input: final_promoted from 01_data_cleaning_and_categorization.sas
Prepares unregistered parcels for model scoring
============================================== */

/* ==============================================
CLEANUP AND PREPARATION
============================================== */

proc casutil;
    droptable casdata="unregistered_parcels_promoted" incaslib="casuser" quiet;
run;

/* ==============================================
UNREGISTERED PARCELS ANALYSIS
Only CKS unregistered parcels - no product analysis needed
============================================== */

data casuser.unregistered_parcels_analysis;
    set casuser.final_promoted;
    
    /* Only CKS unregistered parcels */
    if cks_kaydi_var_mi = 0;
    
    /* Initialize product-related variables as missing/empty for compatibility with 03 */
    length product_list_clean $500 product_list_with_parens $500;
    length nadas_status $15 product_count_category $12;
    
    product_count = 0;
    has_nadas = 0;
    has_other_products = 0;
    product_list_clean = '';
    product_list_with_parens = '';
    nadas_status = 'NO_PRODUCTS';
    product_count_category = 'NO_PRODUCTS';
    
    /* Keep ALL essential variables for model scoring compatibility */
    keep tapuzeminref mahalle primary_category A0_Ekilebilir_Arazi area_hectares
         cks_kaydi_var_mi activity_status has_production
         product_count nadas_status has_nadas has_other_products
         product_count_category product_list_clean product_list_with_parens
         cks_urunler clean_cks_products complete_tapu_description
         has_multiple_categories is_agricultural_relevant
         /* NVDI Variables - Essential for scoring */
         Eyl2023_01Ara2023_median Ara2023_01Sub2024_median Sub2024_01Mar2024_median
         Mar2024_01Nis2024_median Nis2024_01May2024_median May2024_01Haz2024_median
         Haz2024_01Tem2024_median max_monthly_increase significant_increases
         /* Analysis flags */
         inconsistency_flag has_suspicious_production false_declaration
         unregistered_production suspicious_registered cks_beyan_status
         /* Dashboard variables */
         has_production_activity cks_registered_with_production 
         cks_registered_without_prod cks_unregistered_with_production
         cks_unregistered_without_prod cks_status production_status
         combined_status size_category
         /* Additional analysis variables */
         ara_change_pct sub_change_pct mar_change_pct nis_change_pct
         may_change_pct haz_change_pct adequate_size has_high_nvdi
         URL;
    
    /* Labels */
    label
        tapuzeminref = "Parcel ID"
        mahalle = "Neighborhood"
        area_hectares = "Area (Hectares)"
        A0_Ekilebilir_Arazi = "Cultivable Area (m2)"
        product_count = "Number of Products"
        nadas_status = "Fallow Status"
        product_count_category = "Product Count Category"
        product_list_clean = "Clean Product List"
        product_list_with_parens = "Product List with Details"
        cks_urunler = "Original CKS Products";
run;

/* ==============================================
PROMOTE TABLE FOR MODEL SCORING
============================================== */

proc casutil;
    /* Promote unregistered parcels analysis */
    promote casdata="unregistered_parcels_analysis" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="unregistered_parcels_promoted";
run;

/* ==============================================
VERIFICATION REPORTS
============================================== */

/* 1. Check record count */
proc sql;
    select count(*) as unregistered_count
    from casuser.unregistered_parcels_promoted;
    title "Unregistered Parcels Count";
quit;

/* 2. Check data structure */
proc freq data=casuser.unregistered_parcels_promoted;
    tables cks_kaydi_var_mi nadas_status;
    title "Unregistered Parcels Data Check";
run;

/* 3. NVDI data availability check */
proc means data=casuser.unregistered_parcels_promoted n nmiss;
    var Eyl2023_01Ara2023_median Ara2023_01Sub2024_median 
        Mar2024_01Nis2024_median max_monthly_increase area_hectares;
    title "NVDI and Area Data Availability for Unregistered Parcels";
run;

/* ==============================================
CLEANUP TEMPORARY TABLES
============================================== */

proc casutil;
    droptable casdata="unregistered_parcels_analysis" incaslib="casuser" quiet;
run;

/* ==============================================
FINAL STATUS
============================================== */

%put ===============================================;
%put UNREGISTERED PARCELS ANALYSIS COMPLETED;
%put ===============================================;
%put Output table: unregistered_parcels_promoted;
%put Ready for 03_product_categorization processing;
%put Contains only CKS unregistered parcels;
%put Product fields initialized as empty for compatibility;
%put ===============================================;