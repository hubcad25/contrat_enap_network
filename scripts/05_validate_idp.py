
import pandas as pd
import os

def validate_idp_na():
    print("Validating IDP coverage...")
    input_path = 'data/processed/digital_flows.csv.zip'
    output_dir = 'data/validation'
    output_path = os.path.join(output_dir, 'idp_na_report.csv')
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found. Run the merge script first.")
        return

    os.makedirs(output_dir, exist_ok=True)

    # Load data
    df = pd.read_csv(input_path)
    
    # We want to know for each country and year if IDP is missing.
    # IDP is missing for country 'i' in year 't' if it's missing for ALL dyads (i, j) in year 't'.
    # If it's present for at least one dyad (i, j), it means country 'i' has an Ideal Point estimate.
    
    # Calculate if IDP is missing per (country1, year)
    # 0 = Has at least one non-NA IDP
    # 1 = All IDP are NA
    
    coverage = df.groupby(['country1', 'year'])['IDP'].apply(lambda x: 1 if x.isnull().all() else 0).reset_index()
    coverage.rename(columns={'country1': 'country', 'IDP': 'is_na'}, inplace=True)
    
    # Pivot to have years as columns
    report = coverage.pivot(index='country', columns='year', values='is_na')
    
    # Keep only countries that have at least one NA
    report = report[report.sum(axis=1) > 0]
    
    # Sort by country name
    report = report.sort_index()
    
    # Save to CSV
    report.to_csv(output_path)
    print(f"IDP NA report saved to {output_path}")
    print("\nSummary of countries with missing IDP (Years with 1):")
    print(report.head(20)) # Show first 20 to the user

if __name__ == "__main__":
    validate_idp_na()
