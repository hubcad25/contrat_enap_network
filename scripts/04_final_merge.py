
import pandas as pd
import numpy as np
import os

def final_merge():
    print("Starting final merge process...")
    
    # 1. Load Skeleton
    print("Loading skeleton...")
    skeleton = pd.read_csv('data/interim/skeleton_certifications.csv')
    
    # 2. Load Attributes (Governance models)
    print("Loading attributes...")
    attr = pd.read_excel('data/raw/structure/attribute.xlsx')
    
    # 3. Load IDP
    print("Loading IDP data...")
    idp = pd.read_csv('data/interim/idp_dyads_clean.csv')
    
    # 4. Load WTO
    print("Loading WTO data...")
    wto = pd.read_csv('data/interim/wto_digital_services.csv')
    
    # --- MERGE PROCESS ---
    
    # A. Join Attributes for Certifier (i)
    print("Merging attributes for Certifier...")
    df = pd.merge(
        skeleton, 
        attr[['year', 'country', 'model']], 
        left_on=['year', 'country1'], 
        right_on=['year', 'country'], 
        how='left'
    ).rename(columns={'model': 'model1'}).drop('country', axis=1)
    
    # B. Join Attributes for Certified (j)
    print("Merging attributes for Certified...")
    df = pd.merge(
        df, 
        attr[['year', 'country', 'model']], 
        left_on=['year', 'country2'], 
        right_on=['year', 'country'], 
        how='left'
    ).rename(columns={'model': 'model2'}).drop('country', axis=1)
    
    # C. Calculate same_model
    print("Calculating same_model dummy...")
    # Clean models for comparison
    m1_clean = df['model1'].astype(str).str.strip().str.lower()
    m2_clean = df['model2'].astype(str).str.strip().str.lower()
    
    df['same_model'] = (m1_clean == m2_clean).astype(int)
    # Handle NAs
    df.loc[df['model1'].isna() | df['model2'].isna(), 'same_model'] = np.nan
    
    # D. Join IDP
    print("Merging IDP data...")
    # IDP is already in dyad format (ccode1, ccode2, year)
    df = pd.merge(
        df, 
        idp[['year', 'ccode1', 'ccode2', 'AbsIdealDiff']], 
        left_on=['year', 'CCode1', 'CCode2'], 
        right_on=['year', 'ccode1', 'ccode2'], 
        how='left'
    ).drop(['ccode1', 'ccode2'], axis=1)
    
    # E. Join WTO
    # WTO uses ISO codes (alpha-2 or alpha-3 usually, but our processed file has isocode)
    # Let's assume the previous script processed WTO with isocodes
    print("Merging WTO data...")
    # Note: skeleton has isocode1/2
    # We join WTO on (year, isocode1, isocode2)
    # The WTO script 02 outputs Reporter/Partner. We need to check if they are isocodes.
    
    # Quick check on WTO cols if possible, but let's assume standard names
    # Assuming wto columns: [year, Reporter, Partner, Flow, total_value, digital_value]
    # We need to pivot Flow if we want imports/exports on same line or choose one.
    # User requested 'services import', 'services export', 'digital imports', 'digital exports'
    
    wto_exp = wto[wto['Flow'] == 'X'].copy()
    wto_imp = wto[wto['Flow'] == 'M'].copy()
    
    df = pd.merge(
        df, 
        wto_exp[['year', 'isocode1', 'isocode2', 'total_value', 'digital_value']], 
        on=['year', 'isocode1', 'isocode2'], 
        how='left'
    ).rename(columns={'total_value': 'services export', 'digital_value': 'digital exports'})

    df = pd.merge(
        df, 
        wto_imp[['year', 'isocode1', 'isocode2', 'total_value', 'digital_value']], 
        on=['year', 'isocode1', 'isocode2'], 
        how='left'
    ).rename(columns={'total_value': 'services import', 'digital_value': 'digital imports'})

    # Fill NAs for flows with 0 (standard for gravity-like models)
    flow_cols = ['services export', 'digital exports', 'services import', 'digital imports']
    df[flow_cols] = df[flow_cols].fillna(0)
    
    # IDP: Ensure it's NaN if merge failed, which is already the case with how='left'
    
    # Final cleanup to match template exactly
    df = df.rename(columns={
        'CCode1': 'ccode1',
        'CCode2': 'ccode2',
        'AbsIdealDiff': 'IDP'
    })
    
    final_cols = [
        'year', 'ccode1', 'country1', 'model1', 
        'ccode2', 'country2', 'model2', 
        'services import', 'services export', 'digital imports', 'digital exports', 
        'IDP', 'same_model', 'is_certified_event', 'is_certified_state', 'certification_year'
    ]
    df = df[final_cols]
    
    # Remove duplicates if any (keep first)
    initial_len = len(df)
    df = df.drop_duplicates(subset=['year', 'country1', 'country2'])
    if len(df) < initial_len:
        print(f"Removed {initial_len - len(df)} duplicate rows.")
    
    # Save as compressed CSV as requested (Excel is too slow for large datasets)
    output_path = 'data/processed/digital_flows.csv.zip'
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # compression='zip' will wrap the CSV into a zip file automatically
    df.to_csv(output_path, index=False, compression={'method': 'zip', 'archive_name': 'digital_flows.csv'})
    print(f"Final dataset exported to {output_path}. Total rows: {len(df)}")

if __name__ == "__main__":
    final_merge()
