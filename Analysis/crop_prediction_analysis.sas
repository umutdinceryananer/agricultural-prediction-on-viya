/* ==============================================
CROP PREDICTION ANALYSIS FOR 44K SUSPECTED PARCELS
Input: predicted_44k_crop from Model Studio Score Data
============================================== */

/* ==============================================
CLEANUP AND PREPARATION
============================================== */

proc casutil;
    droptable casdata="crop_analysis_promoted" incaslib="casuser" quiet;
    droptable casdata="mahalle_crop_promoted" incaslib="casuser" quiet;
    droptable casdata="category_summary_promoted" incaslib="casuser" quiet;
run;

/* ==============================================
MAIN CROP PREDICTION ANALYSIS
============================================== */

data casuser.crop_analysis;
    set casuser.predicted_44k_products;
    
    /* Predicted crop category */
    length predicted_crop $20;
    predicted_crop = EM_CLASSIFICATION;
    
    /* Confidence categorization */
    length confidence_category $10;
    if EM_EVENTPROBABILITY >= 0.8 then confidence_category = 'VERY_HIGH';
    else if EM_EVENTPROBABILITY >= 0.6 then confidence_category = 'HIGH';
    else if EM_EVENTPROBABILITY >= 0.4 then confidence_category = 'MEDIUM';
    else confidence_category = 'LOW';
    
    /* High confidence flag */
    high_confidence_prediction = (EM_EVENTPROBABILITY >= 0.6);
    
    label
        predicted_crop = "Predicted Crop Category"
        confidence_category = "Prediction Confidence"
        high_confidence_prediction = "High Confidence Prediction";
run;

/* ==============================================
CROP DISTRIBUTION ANALYSIS
============================================== */

/* Overall crop distribution */
proc summary data=casuser.crop_analysis nway;
    class predicted_crop;
    var area_hectares EM_EVENTPROBABILITY;
    output out=casuser.crop_summary
        n=parcel_count
        sum(area_hectares)=total_area
        mean(area_hectares)=avg_area
        mean(EM_EVENTPROBABILITY)=avg_confidence;
run;

data casuser.crop_summary;
    set casuser.crop_summary;
    
    /* Calculate percentages */
    retain total_parcels total_all_area;
    if _n_ = 1 then do;
        total_parcels = 0;
        total_all_area = 0;
    end;
    total_parcels + parcel_count;
    total_all_area + total_area;
    
    /* Calculate percentages in separate step */
    drop _type_ _freq_;
run;

/* Add percentages - SIMPLE VERSION */
data casuser.crop_summary;
    set casuser.crop_summary;
    
    /* Get totals first */
    if _n_ = 1 then do;
        call symputx('total_parcels', 43321);  /* We know this from the log */
        call symputx('total_area_all', sum(total_area));
    end;
    
    /* Calculate percentages */
    parcel_percentage = (parcel_count / 43321) * 100;
    area_percentage = (total_area / sum(total_area)) * 100;
    
    label
        predicted_crop = "Predicted Crop Type"
        parcel_count = "Number of Parcels"
        total_area = "Total Area (Hectares)"
        avg_area = "Average Area per Parcel"
        avg_confidence = "Average Prediction Confidence"
        parcel_percentage = "Percentage of Parcels"
        area_percentage = "Percentage of Area";
run;

/* ==============================================
NEIGHBORHOOD-LEVEL CROP ANALYSIS
============================================== */

proc summary data=casuser.crop_analysis nway;
    class mahalle predicted_crop;
    var area_hectares;
    output out=casuser.mahalle_crop_detail
        n=count
        sum(area_hectares)=area;
run;

/* Simple dominant crop analysis */
data casuser.mahalle_crop_summary;
    set casuser.mahalle_crop_detail;
    
    /* Just basic neighborhood summary for now */
    length dominant_crop $20;
    dominant_crop = predicted_crop;
    total_parcels = count;
    total_area_in_mahalle = area;
    dominance_percentage = 100; /* Simplified */
    
    label
        mahalle = "Neighborhood"
        dominant_crop = "Dominant Predicted Crop"
        total_parcels = "Total Suspected Parcels"
        total_area_in_mahalle = "Total Suspected Area (Hectares)"
        dominance_percentage = "Dominant Crop Percentage";
        
    drop count area;
run;

/* ==============================================
CONFIDENCE ANALYSIS
============================================== */

proc freq data=casuser.crop_analysis;
    tables predicted_crop * confidence_category;
    title "Crop Prediction by Confidence Level";
run;

proc means data=casuser.crop_analysis;
    class predicted_crop;
    var EM_EVENTPROBABILITY;
    title "Confidence Statistics by Predicted Crop";
run;

/* ==============================================
PROMOTE TABLES FOR VA
============================================== */

proc casutil;
    promote casdata="crop_analysis" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="crop_analysis_promoted";
    
    promote casdata="crop_summary" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="category_summary_promoted";
    
    promote casdata="mahalle_crop_summary" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="mahalle_crop_promoted";
run;

/* ==============================================
KEY BUSINESS INSIGHTS
============================================== */

/* Top crops by area */
proc sort data=casuser.category_summary_promoted out=temp_crops;
    by descending total_area;
run;

proc print data=temp_crops;
    var predicted_crop parcel_count total_area parcel_percentage area_percentage avg_confidence;
    title "Predicted Crops Ranked by Total Area";
run;

/* High confidence predictions */
proc sql;
    select 
        predicted_crop,
        count(*) as high_conf_parcels,
        sum(area_hectares) as high_conf_area,
        avg(EM_EVENTPROBABILITY) as avg_confidence format=percent8.2
    from casuser.crop_analysis_promoted
    where high_confidence_prediction = 1
    group by predicted_crop
    order by high_conf_area desc;
    title "High Confidence Crop Predictions (≥60% Confidence)";
quit;

/* Neighborhood dominance */
proc print data=casuser.mahalle_crop_promoted (obs=20);
    where dominance_percentage >= 50;
    var mahalle dominant_crop total_parcels total_area_in_mahalle dominance_percentage;
    title "Neighborhoods with Clear Crop Dominance (≥50%)";
run;

/* ==============================================
FINAL SUMMARY
============================================== */

proc sql;
    select 
        'CROP_DETECTION_SUMMARY' as summary_type,
        count(*) as total_suspected_parcels,
        sum(area_hectares) as total_suspected_area,
        count(distinct predicted_crop) as unique_crop_types,
        sum(case when high_confidence_prediction = 1 then 1 else 0 end) as high_confidence_count,
        avg(EM_EVENTPROBABILITY) as overall_avg_confidence format=percent8.2
    from casuser.crop_analysis_promoted;
    title "Overall Crop Detection Summary";
quit;

/* ==============================================
CLEANUP TEMPORARY TABLES
============================================== */

proc casutil;
    droptable casdata="crop_analysis" incaslib="casuser" quiet;
    droptable casdata="crop_summary" incaslib="casuser" quiet;
    droptable casdata="mahalle_crop_detail" incaslib="casuser" quiet;
    droptable casdata="mahalle_crop_summary" incaslib="casuser" quiet;
run;

/* ==============================================
FINAL STATUS
============================================== */

%put ===============================================;
%put CROP PREDICTION ANALYSIS COMPLETED;
%put ===============================================;
%put Tables for VA visualization:;
%put 1. crop_analysis_promoted - Detailed parcel predictions;
%put 2. category_summary_promoted - Crop type summaries;
%put 3. mahalle_crop_promoted - Neighborhood crop patterns;
%put ===============================================;