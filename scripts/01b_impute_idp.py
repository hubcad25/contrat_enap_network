
import pandas as pd
import numpy as np
import os

def impute_idp_data():
    input_path = 'data/interim/idp_dyads_clean.csv'
    output_path = 'data/interim/idp_countries_imputed.csv'
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found. Run scripts/01_clean_idp_data.py first.")
        return

    print("Loading dyadic IDP data...")
    df = pd.read_csv(input_path)
    
    # 1. Extract individual country-year points
    print("Extracting individual country points...")
    c1 = df[['ccode1', 'year', 'IdealPointFP1']].rename(columns={'ccode1': 'ccode', 'IdealPointFP1': 'IdealPointFP'})
    c2 = df[['ccode2', 'year', 'IdealPointFP2']].rename(columns={'ccode2': 'ccode', 'IdealPointFP2': 'IdealPointFP'})
    
    points = pd.concat([c1, c2]).drop_duplicates().sort_values(['ccode', 'year'])
    
    # 2. Impute for each country
    print("Imputing missing years for each country...")
    
    def impute_nearest(group):
        # We only care about the range 1995-2024 as in skeleton
        years_range = list(range(1995, 2025))
        
        # Get the ccode from the group's name (the grouping key)
        ccode = group.name
        
        # Ensure we have all years in the range
        group = group.set_index('year').reindex(years_range)
        group['ccode'] = ccode
        
        # If there is at least one non-NA value, fill with nearest year
        if group['IdealPointFP'].notna().any():
            # Using ffill().bfill() as a robust alternative to interpolate(nearest) 
            # which requires a newer version of scipy than available.
            group['IdealPointFP'] = group['IdealPointFP'].ffill().bfill()
            
        return group.reset_index()

    imputed = points.groupby('ccode', group_keys=False).apply(impute_nearest)
    
    # Filter out countries that still have no data (e.g. they were never in the original dataset)
    imputed = imputed.dropna(subset=['IdealPointFP'])
    
    # Save imputed points
    imputed.to_csv(output_path, index=False)
    print(f"Imputed country points saved to {output_path}. Total rows: {len(imputed)}")

if __name__ == "__main__":
    impute_idp_data()
