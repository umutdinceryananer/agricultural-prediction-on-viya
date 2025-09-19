/* ==============================================
PARCEL-LEVEL PRODUCT CATEGORIZATION FOR MODELING
Input: parcel_analysis_promoted from 02_urunler_analysis_and_filtering.sas
Adds product category features to each parcel for model training
============================================== */

/* ==============================================
CLEANUP AND PREPARATION
============================================== */

proc casutil;
    droptable casdata="parcel_model_ready_promoted" incaslib="casuser" quiet;
    droptable casdata="category_model_summary_promoted" incaslib="casuser" quiet;
run;

/* ==============================================
PARCEL-LEVEL CATEGORIZATION
Input: parcel_analysis_promoted (parcel-based data)
============================================== */

data casuser.parcel_model_ready;
    set casuser.parcel_analysis_promoted;
    
    /* Initialize category flags */
    length dominant_category $20 secondary_category $20;
    length has_tahil has_baklagil has_yagli_tohum has_sebze has_meyve has_yemlik has_nadas has_endustriyel 8;
    length category_count mixed_category_flag economic_diversity_score 8;
    length seasonal_pattern $15 water_need_level $10;
    
    /* Initialize all flags to 0 */
    has_tahil = 0; has_baklagil = 0; has_yagli_tohum = 0; has_sebze = 0;
    has_meyve = 0; has_yemlik = 0; has_nadas = 0; has_endustriyel = 0;
    category_count = 0;
    economic_diversity_score = 0;
    
    /* Only process parcels with product declarations */
    if product_list_clean ne '' and product_list_clean ne '.' then do;
        
        /* Parse each product in the list */
        product_count_in_parcel = 1 + countc(product_list_clean, ',');
        
        do i = 1 to product_count_in_parcel;
            individual_product = strip(scan(product_list_clean, i, ','));
            
            if individual_product ne '' then do;
                
                /* GRAINS - TAHIL */
                if individual_product in ('BUGDAY','ARPA','YAF','TRITIKALE','MISIR','CAVDAR',
                                         'SILAJLIK MISIR','DANE MISIR','KARABUGDAY') then do;
                    if has_tahil = 0 then do;
                        has_tahil = 1;
                        category_count + 1;
                        economic_diversity_score + 3; /* High value */
                    end;
                end;
                
                /* LEGUMES - BAKLAGIL */
                else if individual_product in ('NOHUT','MERCIMEK','FASULYE','BAKLA','BEZELYE',
                                              'NOHUT MERCIMEK','YEMLIK BEZELYE','BARBUNYA') then do;
                    if has_baklagil = 0 then do;
                        has_baklagil = 1;
                        category_count + 1;
                        economic_diversity_score + 2; /* Medium value */
                    end;
                end;
                
                /* OILSEEDS - YAGLI TOHUM */
                else if individual_product in ('AYCICEGI','KANOLA','SUSAM','ASPIR','KETEN',
                                              'KOLZA','BADEM') then do;
                    if has_yagli_tohum = 0 then do;
                        has_yagli_tohum = 1;
                        category_count + 1;
                        economic_diversity_score + 3; /* High value */
                    end;
                end;
                
                /* VEGETABLES - SEBZE */
                else if individual_product in ('DOMATES','BIBER','PATLICAN','KABAK','HIYAR',
                                              'PATATES','SOGAN','SARIMSAK','LAHANA','MARUL',
                                              'HAVUC','TURP','ISPANAK','PIRASA','MAYDANOZ',
                                              'CARLISTON','KIRMIZI BIBER','TATLI BIBER') then do;
                    if has_sebze = 0 then do;
                        has_sebze = 1;
                        category_count + 1;
                        economic_diversity_score + 2; /* Medium value */
                    end;
                end;
                
                /* FRUITS - MEYVE */
                else if individual_product in ('ELMA','ARMUT','KIRAZ','VISNE','ERIK','KAYISI',
                                              'SEFTALI','UZUM','INCIR','CEVIZ','FINDIK',
                                              'ANTEP FISTIGI','KARPUZ','KAVUN') then do;
                    if has_meyve = 0 then do;
                        has_meyve = 1;
                        category_count + 1;
                        economic_diversity_score + 3; /* High value */
                    end;
                end;
                
                /* FORAGE CROPS - YEMLIK */
                else if individual_product in ('YONCALUCERNE','FIGIKORUNGA','MACAR FIGIKORUNGA',
                                              'YEMLIK SORGUM','SUDAN OTU','KORUNGA',
                                              'YEMLIK PANCAR','SILAJ','YEMLIK BEZELYE',
                                              'YONCA','FIGI') then do;
                    if has_yemlik = 0 then do;
                        has_yemlik = 1;
                        category_count + 1;
                        economic_diversity_score + 1; /* Low value */
                    end;
                end;
                
                /* FALLOW - NADAS */
                else if individual_product = 'NADAS' then do;
                    if has_nadas = 0 then do;
                        has_nadas = 1;
                        category_count + 1;
                        economic_diversity_score + 0; /* No value */
                    end;
                end;
                
                /* INDUSTRIAL/MEDICINAL - ENDUSTRIYEL */
                else if individual_product in ('HASHAS','SEKERPANCARI','PAMUK','TUTUN',
                                              'KENEVIR','KETEN','KIRMIZI PANCARI') then do;
                    if has_endustriyel = 0 then do;
                        has_endustriyel = 1;
                        category_count + 1;
                        economic_diversity_score + 3; /* High value */
                    end;
                end;
            end;
        end;
    end;
    
    /* ==============================================
    DETERMINE DOMINANT AND SECONDARY CATEGORIES
    ============================================== */
    
    /* Find dominant category */
    if has_nadas = 1 and category_count = 1 then dominant_category = 'NADAS';
    else if has_tahil = 1 then dominant_category = 'TAHIL';
    else if has_yagli_tohum = 1 then dominant_category = 'YAGLI_TOHUM';
    else if has_meyve = 1 then dominant_category = 'MEYVE';
    else if has_endustriyel = 1 then dominant_category = 'ENDUSTRIYEL';
    else if has_baklagil = 1 then dominant_category = 'BAKLAGIL';
    else if has_sebze = 1 then dominant_category = 'SEBZE';
    else if has_yemlik = 1 then dominant_category = 'YEMLIK';
    else dominant_category = 'DIGER';
    
    /* Find secondary category (for mixed parcels) */
    if category_count > 1 then do;
        if dominant_category ne 'TAHIL' and has_tahil = 1 then secondary_category = 'TAHIL';
        else if dominant_category ne 'YAGLI_TOHUM' and has_yagli_tohum = 1 then secondary_category = 'YAGLI_TOHUM';
        else if dominant_category ne 'BAKLAGIL' and has_baklagil = 1 then secondary_category = 'BAKLAGIL';
        else if dominant_category ne 'SEBZE' and has_sebze = 1 then secondary_category = 'SEBZE';
        else if dominant_category ne 'YEMLIK' and has_yemlik = 1 then secondary_category = 'YEMLIK';
        else secondary_category = 'NONE';
    end;
    else secondary_category = 'NONE';
    
    /* ==============================================
    DERIVED CATEGORICAL FEATURES FOR MODELING
    ============================================== */
    
    /* Mixed category flag */
    mixed_category_flag = (category_count > 1);
    
    /* Seasonal pattern based on dominant category */
    if dominant_category in ('NADAS') then seasonal_pattern = 'NO_PATTERN';
    else if dominant_category in ('BAKLAGIL') then seasonal_pattern = 'WINTER_SPRING';
    else if dominant_category in ('SEBZE','YAGLI_TOHUM','MEYVE','YEMLIK') then seasonal_pattern = 'SUMMER';
    else if dominant_category in ('TAHIL') then seasonal_pattern = 'WINTER_SUMMER';
    else seasonal_pattern = 'MIXED';
    
    /* Water requirement level */
    if dominant_category in ('SEBZE','MEYVE') then water_need_level = 'HIGH';
    else if dominant_category in ('YAGLI_TOHUM','YEMLIK','ENDUSTRIYEL') then water_need_level = 'MEDIUM';
    else if dominant_category in ('TAHIL','BAKLAGIL') then water_need_level = 'LOW';
    else water_need_level = 'NONE';
    
    /* Economic value category */
    length economic_category $10;
    if economic_diversity_score >= 6 then economic_category = 'HIGH';
    else if economic_diversity_score >= 3 then economic_category = 'MEDIUM';
    else if economic_diversity_score >= 1 then economic_category = 'LOW';
    else economic_category = 'NONE';
    
    /* ==============================================
    MODEL-READY FLAGS
    ============================================== */
    
    /* Binary flags for specific model features */
    is_monoculture = (category_count = 1 and dominant_category ne 'NADAS');
    is_diversified = (category_count >= 3);
    has_high_value_crops = (has_tahil = 1 or has_yagli_tohum = 1 or has_meyve = 1 or has_endustriyel = 1);
    is_subsistence_farming = (has_sebze = 1 and area_hectares <= 0.5);
    is_commercial_farming = (area_hectares > 2 and has_high_value_crops = 1);
    
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
        is_commercial_farming = "Commercial Farming Pattern";
    
    /* Drop temporary variables */
    drop i individual_product product_count_in_parcel;
run;

/* ==============================================
CREATE MODEL SUMMARY STATISTICS
============================================== */

proc summary data=casuser.parcel_model_ready nway;
    class dominant_category cks_kaydi_var_mi;
    var area_hectares economic_diversity_score category_count;
    output out=casuser.category_model_summary
        n=parcel_count
        mean(area_hectares)=avg_area
        sum(area_hectares)=total_area
        mean(economic_diversity_score)=avg_economic_score
        mean(category_count)=avg_category_count;
run;

data casuser.category_model_summary;
    set casuser.category_model_summary;
    drop _type_ _freq_;
run;

/* ==============================================
PROMOTE TABLES FOR MODELING
============================================== */

proc casutil;
    /* Promote model-ready dataset */
    promote casdata="parcel_model_ready" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="parcel_model_ready_promoted";
    
    /* Promote summary statistics */
    promote casdata="category_model_summary" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="category_model_summary_promoted";
run;

/* ==============================================
VERIFICATION REPORTS
============================================== */

/* 1. Category distribution for CKS registered parcels */
proc freq data=casuser.parcel_model_ready_promoted;
    tables dominant_category;
    where cks_kaydi_var_mi = 1;
    title "Dominant Category Distribution (CKS Registered Parcels Only)";
run;

/* 2. Model features summary */
proc means data=casuser.parcel_model_ready_promoted n mean std;
    var category_count economic_diversity_score area_hectares;
    where cks_kaydi_var_mi = 1;
    title "Model Features Summary Statistics (Training Data)";
run;

/* 3. Mixed category analysis */
proc freq data=casuser.parcel_model_ready_promoted;
    tables mixed_category_flag * dominant_category;
    where cks_kaydi_var_mi = 1;
    title "Mixed Category Analysis (CKS Registered)";
run;

/* ==============================================
CLEANUP TEMPORARY TABLES
============================================== */

proc casutil;
    droptable casdata="parcel_model_ready" incaslib="casuser" quiet;
    droptable casdata="category_model_summary" incaslib="casuser" quiet;
run;

/* ==============================================
FINAL STATUS
============================================== */

%put ===============================================;
%put PARCEL-LEVEL CATEGORIZATION COMPLETED;
%put ===============================================;
%put Model-ready table: parcel_model_ready_promoted;
%put Features added:;
%put - Binary category flags (has_tahil, has_baklagil, etc.);
%put - Dominant/secondary categories;
%put - Economic diversity score;
%put - Seasonal pattern;  
%put - Farming type flags (monoculture, commercial, etc.);
%put ===============================================;
%put Ready for model training on CKS registered parcels;
%put ===============================================;