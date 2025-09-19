/* ==============================================
MAHALLE HEATMAP DATA PREPARATION FOR VA
Heat map showing unregistered production by neighborhood
============================================== */

/* Clear any existing heatmap table */
proc casutil;
    droptable casdata="mahalle_heatmap" incaslib="casuser" quiet;
	droptable casdata="mahalle_heatmap_final" incaslib="casuser" quiet;
run;

/* Create heatmap data directly */
proc summary data=casuser.final_promoted nway;
    class mahalle;
    var unregistered_production;
    output out=casuser.mahalle_heatmap_final
           n=total_cnt
           sum=unreg_prod_cnt;
run;

/* Calculate percentages in place */
data casuser.mahalle_heatmap_final;
    set casuser.mahalle_heatmap_final;
    
    /* Calculate percentage */
    if total_cnt > 0 then
        unreg_prod_pct = round((unreg_prod_cnt / total_cnt) * 100, 0.1);
    else
        unreg_prod_pct = 0;
    
    /* Keep only necessary variables */
    keep mahalle total_cnt unreg_prod_cnt unreg_prod_pct;
    
    /* Labels for VA */
    label
        mahalle = "Neighborhood"
        total_cnt = "Total Parcels"
        unreg_prod_cnt = "Unregistered Production Count"
        unreg_prod_pct = "Unregistered Production %";
        
    format unreg_prod_pct 5.1;
run;

/* Promote final table */
proc casutil;
    promote casdata="mahalle_heatmap_final" 
            incaslib="casuser";
run;

%put Heatmap dataset ready: mahalle_heatmap_final;