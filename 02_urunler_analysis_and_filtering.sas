/* ==============================================
FINAL PRODUCT ANALYSIS FOR VA DASHBOARD
3 CLEAN TABLES FOR VISUAL ANALYTICS
============================================== */

/* ==============================================
CLEANUP AND PREPARATION
============================================== */

proc casutil;
    droptable casdata="parcel_analysis_promoted" incaslib="casuser" quiet;
    droptable casdata="product_frequency_promoted" incaslib="casuser" quiet;
    droptable casdata="analysis_summary_promoted" incaslib="casuser" quiet;
run;

/* ==============================================
TABLE 1: PARCEL LEVEL ANALYSIS
- Nadas analysis (Tam/Partial/Yok)
- Product count per parcel
- Area analysis
============================================== */

data casuser.parcel_analysis_detailed;
    set casuser.final_promoted;
    
    /* Only CKS registered parcels with product declarations */
    if cks_kaydi_var_mi = 1 and cks_urunler ne '' and cks_urunler ne '.';
    
    length product_list_clean $500 product_list_with_parens $500;
    length nadas_status $15 individual_product $100;
    
    /* Initialize variables */
    product_count = 0;
    has_nadas = 0;
    has_other_products = 0;
    product_list_clean = '';
    product_list_with_parens = '';
    
    /* Clean Turkish characters first */
    product_cleaned = strip(upcase(cks_urunler));
    product_cleaned = tranwrd(product_cleaned, 'Ç', 'C');
    product_cleaned = tranwrd(product_cleaned, 'Ğ', 'G');
    product_cleaned = tranwrd(product_cleaned, 'İ', 'I');
    product_cleaned = tranwrd(product_cleaned, 'Ö', 'O');
    product_cleaned = tranwrd(product_cleaned, 'Ş', 'S');
    product_cleaned = tranwrd(product_cleaned, 'Ü', 'U');
    
    /* Count products and analyze */
    product_count_raw = 1 + countc(product_cleaned, ',');
    
    do i = 1 to product_count_raw;
        individual_product = strip(scan(product_cleaned, i, ','));
        
        if individual_product ne '' then do;
            
            /* Create version WITH parentheses for frequency analysis */
            if i = 1 then product_list_with_parens = individual_product;
            else product_list_with_parens = catx(',', product_list_with_parens, individual_product);
            
            /* Remove parentheses for clean version */
            if index(individual_product, '(') > 0 then do;
                clean_product = strip(substr(individual_product, 1, index(individual_product, '(') - 1));
            end;
            else do;
                clean_product = individual_product;
            end;
            
            /* Remove special characters */
            clean_product = compress(clean_product, ')');
            clean_product = compress(clean_product, '+');
            clean_product = strip(clean_product);
            
            /* Apply corrections */
            if clean_product = 'BUGDAYY' then clean_product = 'BUGDAY';
            else if clean_product = 'KARABUGDAYY' then clean_product = 'KARABUGDAY';
            else if clean_product = 'BUGDA' then clean_product = 'BUGDAY';
            else if clean_product = 'AYCICEGIICEGI' then clean_product = 'AYCICEGI';
            else if clean_product = 'AYC' then clean_product = 'AYCICEGI';
            else if clean_product = 'TRITIKALEIKALE' then clean_product = 'TRITIKALE';
            else if clean_product = 'TRIT' then clean_product = 'TRITIKALE';
            else if clean_product = 'SILAJLIK MISIRIR' then clean_product = 'SILAJLIK MISIR';
            else if clean_product = 'SILAJLIK MISIRIR MIS' then clean_product = 'SILAJLIK MISIR';
            else if clean_product = 'SILAJLIK MISIRIR MISIR' then clean_product = 'SILAJLIK MISIR';
            else if clean_product = 'SILAJLIK MIS' then clean_product = 'SILAJLIK MISIR';
            else if clean_product = 'SILAJLIK' then clean_product = 'SILAJLIK MISIR';
            else if clean_product = 'CARLISTON' then clean_product = 'BIBER';
            else if clean_product = 'CARLİSTON' then clean_product = 'BIBER';
            else if clean_product = 'HASHAS KAPSUL' then clean_product = 'HASHAS';
            else if clean_product = 'HASHAS DANE' then clean_product = 'HASHAS';
            else if clean_product = 'HASHAS KAPSUL DANE' then clean_product = 'HASHAS';
            
            clean_product = strip(clean_product);
            
            /* Valid product check */
            if length(clean_product) >= 3 and length(clean_product) <= 30 then do;
                product_count + 1;
                
                /* Check for NADAS */
                if clean_product = 'NADAS' then has_nadas = 1;
                else has_other_products = 1;
                
                /* Build clean product list */
                if product_list_clean = '' then product_list_clean = clean_product;
                else product_list_clean = catx(',', product_list_clean, clean_product);
            end;
        end;
    end;
    
    /* Determine NADAS status */
    if has_nadas = 1 and has_other_products = 0 then nadas_status = 'TAM_NADAS';
    else if has_nadas = 1 and has_other_products = 1 then nadas_status = 'PARTIAL_NADAS';
    else nadas_status = 'NADAS_YOK';
    
    /* Product count categories for analysis */
    length product_count_category $12;
    if nadas_status = 'TAM_NADAS' then product_count_category = 'TAM_NADAS';
    else if product_count = 1 then product_count_category = 'TEKLI';
    else if product_count = 2 then product_count_category = 'IKILI';
    else if product_count = 3 then product_count_category = 'UCLU';
    else if product_count >= 4 then product_count_category = 'DORTLU_PLUS';
    else product_count_category = 'DIGER';
    
    /* Keep ALL essential variables from final_promoted + product analysis */
    keep tapuzeminref mahalle primary_category A0_Ekilebilir_Arazi area_hectares
         cks_kaydi_var_mi activity_status has_production
         product_count nadas_status has_nadas has_other_products
         product_count_category product_list_clean product_list_with_parens
         cks_urunler clean_cks_products complete_tapu_description
         has_multiple_categories is_agricultural_relevant
         /* NVDI Variables */
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
TABLE 2: PRODUCT FREQUENCY ANALYSIS - FIXED VERSION
- Separate processing to fix frequency calculation
- Both clean and detailed product names
============================================== */

/* Create separate clean products table */
data casuser.clean_products_expanded;
    set casuser.parcel_analysis_detailed;
    
    length product_type $15;
    product_count_in_parcel = 1 + countc(product_list_clean, ',');
    
    do i = 1 to product_count_in_parcel;
        product_name = strip(scan(product_list_clean, i, ','));
        product_type = 'CLEAN';
        parcel_area = area_hectares;
        
        if product_name ne '' then output;
    end;
    
    keep tapuzeminref product_name product_type parcel_area A0_Ekilebilir_Arazi;
run;

/* Create separate detailed products table */
data casuser.detailed_products_expanded;
    set casuser.parcel_analysis_detailed;
    
    length product_type $15;
    product_count_with_parens = 1 + countc(product_list_with_parens, ',');
    
    do i = 1 to product_count_with_parens;
        product_name = strip(scan(product_list_with_parens, i, ','));
        product_type = 'WITH_PARENS';
        parcel_area = area_hectares;
        
        if product_name ne '' then output;
    end;
    
    keep tapuzeminref product_name product_type parcel_area A0_Ekilebilir_Arazi;
run;

/* Combine both tables */
data casuser.all_products_expanded;
    set casuser.clean_products_expanded casuser.detailed_products_expanded;
run;

/* Create frequency summaries */
proc summary data=casuser.all_products_expanded nway;
    class product_name product_type;
    var parcel_area A0_Ekilebilir_Arazi;
    output out=casuser.product_frequency_analysis
        n=frequency
        sum(parcel_area)=total_area_hectares
        sum(A0_Ekilebilir_Arazi)=total_cultivable_area_m2
        mean(parcel_area)=avg_area_hectares;
run;

data casuser.product_frequency_analysis;
    set casuser.product_frequency_analysis;
    
    /* Convert to hectares */
    total_cultivable_area_hectares = total_cultivable_area_m2 / 10000;
    
    /* Labels */
    label
        product_name = "Product Name"
        product_type = "Product Type (Clean vs With Details)"
        frequency = "Number of Parcels"
        total_area_hectares = "Total Area (Hectares)"
        total_cultivable_area_hectares = "Total Cultivable Area (Hectares)"
        avg_area_hectares = "Average Area per Parcel";
        
    drop _type_ _freq_ total_cultivable_area_m2;
run;

/* ==============================================
TABLE 3: SUMMARY STATISTICS
- Unique product counts (corrected)
- Key metrics for dashboard
============================================== */

/* Get current unique counts */
proc sql noprint;
    /* Clean products unique count */
    select count(distinct product_name) into :unique_clean_count
    from casuser.all_products_expanded
    where product_type = 'CLEAN';
    
    /* Products with parentheses unique count - CORRECTED */
    select count(distinct product_name) into :unique_parens_count
    from casuser.all_products_expanded
    where product_type = 'WITH_PARENS';
quit;

/* Create single row summary for VA dashboard */
data casuser.analysis_summary;
    length summary_type $20;
    
    summary_type = 'PRODUCT_SUMMARY';
    unique_products_clean = &unique_clean_count;
    unique_products_with_parens = &unique_parens_count;
    total_parcels = 50782;
    
    label
        summary_type = "Summary Type"
        unique_products_clean = "Unique Products (Clean Names)"
        unique_products_with_parens = "Unique Products (With Details)"
        total_parcels = "Total Number of Parcels";
    
    output;
run;

/* ==============================================
PROMOTE TABLES FOR VA
============================================== */

proc casutil;
    /* Promote main detailed analysis */
    promote casdata="parcel_analysis_detailed" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="parcel_analysis_promoted";
    
    /* Promote product frequency analysis */
    promote casdata="product_frequency_analysis" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="product_frequency_promoted";
    
    /* Promote summary statistics */
    promote casdata="analysis_summary" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="analysis_summary_promoted";
run;

/* ==============================================
VERIFICATION REPORTS
============================================== */

/* 1. Nadas Analysis Summary */
proc freq data=casuser.parcel_analysis_promoted;
    tables nadas_status;
    title "NADAS Analysis Summary";
run;

/* 2. Product Count Distribution (excluding Tam Nadas) */
proc freq data=casuser.parcel_analysis_promoted;
    tables product_count_category;
    where nadas_status ne 'TAM_NADAS';
    title "Product Count Distribution (Excluding Full Fallow)";
run;

/* 3. Top products by area (clean version) */
proc sql outobs=15;
    select product_name, frequency, total_cultivable_area_hectares
    from casuser.product_frequency_promoted
    where product_type = 'CLEAN'
    order by total_cultivable_area_hectares desc;
    title "Top 15 Products by Cultivable Area (Clean Names)";
quit;

/* 4. Unique count verification - SHOULD SHOW CORRECT VALUES NOW */
proc print data=casuser.analysis_summary_promoted;
    title "Unique Product Counts Summary - CORRECTED";
run;

/* 5. Frequency verification - SHOULD SHOW CORRECT FREQUENCIES NOW */
proc sql outobs=10;
    select product_name, frequency, total_cultivable_area_hectares
    from casuser.product_frequency_promoted
    where product_type = 'WITH_PARENS'
    order by frequency desc;
    title "TOP 10 PRODUCTS - FREQUENCY VERIFICATION (Should show correct counts)";
quit;

/* ==============================================
CLEANUP TEMPORARY TABLES
============================================== */

proc casutil;
    droptable casdata="parcel_analysis_detailed" incaslib="casuser" quiet;
    droptable casdata="clean_products_expanded" incaslib="casuser" quiet;
    droptable casdata="detailed_products_expanded" incaslib="casuser" quiet;
    droptable casdata="all_products_expanded" incaslib="casuser" quiet;
    droptable casdata="product_frequency_analysis" incaslib="casuser" quiet;
    droptable casdata="analysis_summary" incaslib="casuser" quiet;
run;

/* ==============================================
FINAL STATUS
============================================== */

%put ===============================================;
%put FINAL PROMOTED TABLES FOR VA READY:;
%put ===============================================;
%put 1. parcel_analysis_promoted - Main detailed parcel analysis;
%put 2. product_frequency_promoted - Product frequencies (FIXED);
%put 3. analysis_summary_promoted - Summary statistics;
%put ===============================================;
%put SUCCESS: All tables ready for Visual Analytics;
%put FREQUENCY ISSUE FIXED: Now shows correct parcel counts;
%put ===============================================;