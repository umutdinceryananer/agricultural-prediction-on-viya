/* ==============================================
SCORING RESULTS ANALYSIS
Input: Scored table from Model Studio Score Data component
Analyzes EM_CLASSIFICATION, EM_EVENTPROBABILITY, and EM_PROBABILITY
============================================== */

/* ==============================================
CLEANUP AND PREPARATION
============================================== */

proc casutil;
    droptable casdata="scoring_analysis_promoted" incaslib="casuser" quiet;
    droptable casdata="mahalle_analysis_promoted" incaslib="casuser" quiet;
    droptable casdata="risk_categories_promoted" incaslib="casuser" quiet;
run;

/* ==============================================
INPUT SCORED TABLE ANALYSIS
NOTE: Change table name to match your Score Data output
============================================== */

data casuser.scoring_analysis;
    set casuser.unreg_table_scored; /* Corrected table name */
    
    /* Create probability categories for analysis */
    length probability_category $15 risk_level $10;
    
    /* Categorize event probability */
    if EM_EVENTPROBABILITY >= 0.8 then probability_category = 'VERY_HIGH_80+';
    else if EM_EVENTPROBABILITY >= 0.6 then probability_category = 'HIGH_60-80';
    else if EM_EVENTPROBABILITY >= 0.4 then probability_category = 'MEDIUM_40-60';
    else if EM_EVENTPROBABILITY >= 0.2 then probability_category = 'LOW_20-40';
    else probability_category = 'VERY_LOW_0-20';
    
    /* Risk level for business decisions */
    if EM_EVENTPROBABILITY >= 0.7 then risk_level = 'HIGH';
    else if EM_EVENTPROBABILITY >= 0.5 then risk_level = 'MEDIUM';
    else risk_level = 'LOW';
    
    /* Flag for suspected unregistered production */
    suspected_unregistered = (EM_CLASSIFICATION = "Production Detected");
    
    /* High confidence prediction flag */
    high_confidence = (EM_EVENTPROBABILITY >= 0.7 or EM_EVENTPROBABILITY <= 0.3);
    
    /* Labels */
    label
        EM_CLASSIFICATION = "Model Prediction (0=No Production, 1=Production)"
        EM_EVENTPROBABILITY = "Probability of Production"
        EM_PROBABILITY = "Model Probability Score"
        probability_category = "Probability Range Category"
        risk_level = "Risk Level for Investigation"
        suspected_unregistered = "Suspected Unregistered Production"
        high_confidence = "High Confidence Prediction";
run;

/* ==============================================
SUMMARY STATISTICS
============================================== */

/* 1. Overall Classification Results */
proc freq data=casuser.scoring_analysis;
    tables EM_CLASSIFICATION probability_category risk_level;
    title "Overall Scoring Results Distribution";
run;

/* 2. Event Probability Statistics */
proc means data=casuser.scoring_analysis n mean std min max p10 p25 p50 p75 p90;
    var EM_EVENTPROBABILITY EM_PROBABILITY;
    title "Event Probability Distribution Statistics";
run;

/* 3. Cross-tabulation */
proc freq data=casuser.scoring_analysis;
    tables EM_CLASSIFICATION * probability_category;
    title "Classification vs Probability Category";
run;

/* ==============================================
NEIGHBORHOOD-LEVEL ANALYSIS
============================================== */

proc summary data=casuser.scoring_analysis nway;
    class mahalle;
    var suspected_unregistered EM_EVENTPROBABILITY area_hectares;
    output out=casuser.mahalle_analysis
        n=total_parcels
        sum(suspected_unregistered)=suspected_count
        mean(EM_EVENTPROBABILITY)=avg_probability
        sum(area_hectares)=total_area
        max(EM_EVENTPROBABILITY)=max_probability;
run;

data casuser.mahalle_analysis;
    set casuser.mahalle_analysis;
    
    /* Calculate percentages and risk metrics */
    suspected_percentage = (suspected_count / total_parcels) * 100;
    
    /* Neighborhood risk classification */
    length neighborhood_risk $15;
    if suspected_percentage >= 50 then neighborhood_risk = 'VERY_HIGH';
    else if suspected_percentage >= 30 then neighborhood_risk = 'HIGH';
    else if suspected_percentage >= 15 then neighborhood_risk = 'MEDIUM';
    else neighborhood_risk = 'LOW';
    
    /* Labels */
    label
        mahalle = "Neighborhood"
        total_parcels = "Total Unregistered Parcels"
        suspected_count = "Suspected Production Count"
        suspected_percentage = "Percentage with Suspected Production"
        avg_probability = "Average Production Probability"
        total_area = "Total Area (Hectares)"
        max_probability = "Highest Production Probability"
        neighborhood_risk = "Neighborhood Risk Level";
        
    drop _type_ _freq_;
run;

/* ==============================================
RISK CATEGORY ANALYSIS
============================================== */

proc summary data=casuser.scoring_analysis nway;
    class risk_level;
    var area_hectares EM_EVENTPROBABILITY;
    output out=casuser.risk_categories
        n=parcel_count
        sum(area_hectares)=total_area
        mean(area_hectares)=avg_area
        mean(EM_EVENTPROBABILITY)=avg_probability;
run;

data casuser.risk_categories;
    set casuser.risk_categories;
    
    /* Calculate area percentages */
    total_all_area = 50782; /* Approximate from previous analyses */
    area_percentage = (parcel_count / total_all_area) * 100;
    
    drop _type_ _freq_;
    
    label
        risk_level = "Risk Level"
        parcel_count = "Number of Parcels"
        total_area = "Total Area (Hectares)"
        avg_area = "Average Area per Parcel"
        avg_probability = "Average Production Probability"
        area_percentage = "Percentage of All Unregistered Parcels";
run;

/* ==============================================
PROMOTE TABLES FOR DASHBOARD
============================================== */

proc casutil;
    /* Promote detailed analysis */
    promote casdata="scoring_analysis" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="scoring_analysis_promoted";
    
    /* Promote neighborhood analysis */
    promote casdata="mahalle_analysis" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="mahalle_analysis_promoted";
    
    /* Promote risk categories */
    promote casdata="risk_categories" 
            incaslib="casuser" 
            outcaslib="casuser" 
            casout="risk_categories_promoted";
run;

/* ==============================================
DETAILED REPORTS
============================================== */

/* 1. High-Risk Neighborhoods (>30% suspected) */
proc print data=casuser.mahalle_analysis_promoted;
    where suspected_percentage > 30;
    var mahalle total_parcels suspected_count suspected_percentage 
        avg_probability total_area neighborhood_risk;
    title "High-Risk Neighborhoods (>30% Suspected Production)";
run;

/* 2. Top 20 Neighborhoods by Suspected Count */
proc sort data=casuser.mahalle_analysis_promoted out=temp_mahalle;
    by descending suspected_count;
run;

proc print data=temp_mahalle (obs=20);
    var mahalle total_parcels suspected_count suspected_percentage 
        avg_probability total_area;
    title "Top 20 Neighborhoods by Suspected Production Count";
run;

/* 3. Risk Level Summary */
proc print data=casuser.risk_categories_promoted;
    var risk_level parcel_count area_percentage total_area avg_probability;
    title "Risk Level Summary";
run;

/* 4. High Confidence Predictions */
proc sql;
    select 
        'HIGH_CONFIDENCE' as analysis_type,
        count(*) as total_parcels,
        sum(case when EM_CLASSIFICATION = "Production Detected" then 1 else 0 end) as predicted_production,
        sum(case when EM_CLASSIFICATION = "No Production" then 1 else 0 end) as predicted_no_production,
        mean(EM_EVENTPROBABILITY) as avg_event_probability format=percent8.2
    from casuser.scoring_analysis_promoted
    where high_confidence = 1;
    title "High Confidence Predictions Summary";
quit;

/* 5. Probability Distribution */
proc univariate data=casuser.scoring_analysis_promoted;
    var EM_EVENTPROBABILITY;
    histogram EM_EVENTPROBABILITY;
    title "Event Probability Distribution";
run;

/* ==============================================
BUSINESS INSIGHTS
============================================== */

proc sql;
    select 
        'BUSINESS_SUMMARY' as summary_type,
        count(*) as total_unregistered_parcels,
        sum(suspected_unregistered) as suspected_production_parcels,
        calculated suspected_production_parcels / calculated total_unregistered_parcels * 100 as suspected_percentage format=5.1,
        sum(case when risk_level = 'HIGH' then 1 else 0 end) as high_risk_parcels,
        sum(case when risk_level = 'HIGH' then area_hectares else 0 end) as high_risk_area format=8.1,
        mean(EM_EVENTPROBABILITY) as overall_avg_probability format=percent8.2
    from casuser.scoring_analysis_promoted;
    title "Business Summary - Unregistered Production Detection";
quit;

/* ==============================================
CLEANUP TEMPORARY TABLES
============================================== */

proc casutil;
    droptable casdata="scoring_analysis" incaslib="casuser" quiet;
    droptable casdata="mahalle_analysis" incaslib="casuser" quiet;
    droptable casdata="risk_categories" incaslib="casuser" quiet;
run;

/* ==============================================
FINAL STATUS
============================================== */

%put ===============================================;
%put SCORING RESULTS ANALYSIS COMPLETED;
%put ===============================================;
%put Tables ready for dashboard:;
%put 1. scoring_analysis_promoted - Detailed parcel-level results;
%put 2. mahalle_analysis_promoted - Neighborhood-level analysis;
%put 3. risk_categories_promoted - Risk level summaries;
%put ===============================================;
%put Key metrics analyzed:;
%put - EM_CLASSIFICATION: Model predictions;
%put - EM_EVENTPROBABILITY: Production probabilities;
%put - Risk levels and confidence measures;
%put ===============================================;