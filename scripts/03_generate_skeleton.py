
import pandas as pd
import numpy as np
import os

def generate_skeleton():
    # Load sources
    attr = pd.read_excel('data/raw/structure/attribute.xlsx')
    cow = pd.read_csv('data/raw/COW-country-codes.csv')
    # Load certifications with correct header and clean it
    certif = pd.read_excel('data/raw/Data.xlsx', header=1)
    certif = certif.dropna(subset=['Certifier', 'Certified', 'Year'])
    certif['Year'] = certif['Year'].astype(int)

    # Custom mapping for COW codes mismatches
    name_map = {
        'United States': 'United States of America',
        'Russian Federation': 'Russia',
        'Slovak Republic': 'Slovakia',
        'The Philippines': 'Philippines',
        'North Macedonia': 'Macedonia',
        'Congo DRC': 'Democratic Republic of the Congo',
        'Cabo Verde': 'Cape Verde',
        'Timor-Leste': 'East Timor',
        'Eswatini': 'Swaziland',
        "Côte d'Ivoire": 'Ivory Coast',
        'Brunei Darussalam': 'Brunei',
        'Viet Nam': 'Vietnam',
        'Saint Lucia': 'St. Lucia',
        'Antigua and Barbuda': 'Antigua & Barbuda'
    }
    
    attr['country_cow'] = attr['country'].replace(name_map)
    
    # Merge to get ccode for each country in attr
    cow_unique = cow[['StateNme', 'CCode']].drop_duplicates(subset=['StateNme'])
    
    # Union countries from attr and WTO to ensure coverage
    wto = pd.read_csv('data/interim/wto_digital_services.csv')
    wto_iso = set(wto['isocode1'].unique()) | set(wto['isocode2'].unique())
    attr_iso = set(attr['isocode'].unique())
    all_iso = attr_iso | wto_iso
    
    # Create a base country mapping from all ISO codes
    # Prefer names from attr if available
    base_mapping = []
    attr_subset = attr[['country', 'isocode']].drop_duplicates(subset=['isocode'])
    attr_map = dict(zip(attr_subset['isocode'], attr_subset['country']))
    
    # ISO to Name map for WTO-only countries (best effort)
    iso_to_name = {
        'KNA': 'Saint Kitts and Nevis',
        'SYC': 'Seychelles',
        'CYM': 'Cayman Islands',
        'FRO': 'Faroe Islands',
        'SLE': 'Sierra Leone',
        'SXM': 'Sint Maarten',
        'WSM': 'Samoa',
        'VCT': 'Saint Vincent and the Grenadines'
    }
    
    for iso in all_iso:
        name = attr_map.get(iso) or iso_to_name.get(iso) or iso
        base_mapping.append({'country': name, 'isocode': iso})
    
    mapping_df = pd.DataFrame(base_mapping)
    mapping_df['country_cow'] = mapping_df['country'].replace(name_map)
    
    mapping = pd.merge(
        mapping_df, 
        cow_unique, 
        left_on='country_cow', 
        right_on='StateNme', 
        how='left'
    )

    # Generate Skeleton
    # Years: attributes go to 2023, but WTO has 2024
    years = sorted(list(attr['year'].unique()) + [2024])
    skeleton_list = []
    
    for year in years:
        # Get countries for this year. For 2024, we take all known countries.
        nodes = mapping.copy()
        nodes['key'] = 1
        dyads = pd.merge(nodes, nodes, on='key', suffixes=('1', '2'))
        dyads = dyads[dyads['isocode1'] != dyads['isocode2']]
        dyads['year'] = year
        skeleton_list.append(dyads.drop('key', axis=1))

    skeleton = pd.concat(skeleton_list)

    # Normalize Data.xlsx names to match attribute.xlsx
    certif_map = {
        'United States of America': 'United States',
        'Russia': 'Russian Federation',
        'Slovakia': 'Slovak Republic',
        'Brunei': 'Brunei Darussalam',
        'Cape Verde': 'Cabo Verde',
        'Democratic Republic of Congo': 'Congo DRC',
        'DR Congo': 'Congo DRC',
        'Republic of Congo': 'Congo',
        'Ivory Coast': "Côte d'Ivoire",
        'Republic of Korea': 'South Korea',
        'Korea': 'South Korea',
        'Saudi Arabia ': 'Saudi Arabia',
        'Lichtenstein': 'Liechtenstein'
    }
    certif['Certifier'] = certif['Certifier'].replace(certif_map)
    certif['Certified'] = certif['Certified'].replace(certif_map)

    # Join with Certifications
    # Drop duplicates to avoid expansion, keep minimum year as first certification
    certif_first = certif.groupby(['Certifier', 'Certified'])['Year'].min().reset_index()
    certif_first.rename(columns={'Year': 'certification_year'}, inplace=True)

    # For event: we need all (Certifier, Certified, Year) combinations
    certif['is_certified_event'] = 1
    
    # Merge events
    skeleton = pd.merge(
        skeleton, 
        certif[['Certifier', 'Certified', 'Year', 'is_certified_event']], 
        left_on=['country1', 'country2', 'year'], 
        right_on=['Certifier', 'Certified', 'Year'], 
        how='left'
    )
    skeleton['is_certified_event'] = skeleton['is_certified_event'].fillna(0).astype(int)
    skeleton = skeleton.drop(['Certifier', 'Certified', 'Year'], axis=1)

    # Merge first certification year for state logic
    skeleton = pd.merge(
        skeleton,
        certif_first,
        left_on=['country1', 'country2'],
        right_on=['Certifier', 'Certified'],
        how='left'
    )
    skeleton['is_certified_state'] = (skeleton['year'] >= skeleton['certification_year']).astype(int)
    # If certification_year is NaN, is_certified_state should be 0
    skeleton.loc[skeleton['certification_year'].isna(), 'is_certified_state'] = 0

    # Cleanup columns
    final_cols = [
        'year', 'country1', 'isocode1', 'CCode1', 
        'country2', 'isocode2', 'CCode2', 
        'is_certified_event', 'is_certified_state', 'certification_year'
    ]
    skeleton = skeleton[final_cols]
    
    output_path = 'data/interim/skeleton_certifications.csv'
    skeleton.to_csv(output_path, index=False)
    print(f"Skeleton generated in {output_path}: {len(skeleton)} rows.")

if __name__ == "__main__":
    generate_skeleton()
