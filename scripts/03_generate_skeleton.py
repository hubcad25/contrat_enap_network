
import pandas as pd
import numpy as np
import os

def generate_skeleton():
    # Load sources
    attr = pd.read_excel('data/raw/structure/attribute.xlsx')
    cow = pd.read_csv('data/raw/COW-country-codes.csv')
    certif = pd.read_excel('data/raw/Data.xlsx', header=0)
    certif.columns = ['Certifier', 'Certified', 'Year']

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
        'Cote d\'Ivoire': 'Ivory Coast',
        'Brunei Darussalam': 'Brunei',
        'Viet Nam': 'Vietnam',
        'Saint Lucia': 'St. Lucia',
        'Antigua and Barbuda': 'Antigua & Barbuda'
    }
    
    attr['country_cow'] = attr['country'].replace(name_map)
    
    # Merge to get ccode for each country in attr
    cow_unique = cow[['StateNme', 'CCode']].drop_duplicates(subset=['StateNme'])
    mapping = pd.merge(
        attr[['country', 'country_cow', 'isocode']].drop_duplicates(), 
        cow_unique, 
        left_on='country_cow', 
        right_on='StateNme', 
        how='left'
    )

    # Generate Skeleton
    years = sorted(attr['year'].unique())
    skeleton_list = []
    
    for year in years:
        # Get countries with valid CCode for this year
        nodes = mapping.dropna(subset=['CCode']).copy()
        nodes['key'] = 1
        dyads = pd.merge(nodes, nodes, on='key', suffixes=('1', '2'))
        dyads = dyads[dyads['country1'] != dyads['country2']]
        dyads['year'] = year
        skeleton_list.append(dyads.drop('key', axis=1))

    skeleton = pd.concat(skeleton_list)

    # Join with Certifications (using original names from attr)
    certif['is_certified'] = 1
    skeleton = pd.merge(
        skeleton, 
        certif, 
        left_on=['country1', 'country2', 'year'], 
        right_on=['Certifier', 'Certified', 'Year'], 
        how='left'
    )
    skeleton['is_certified'] = skeleton['is_certified'].fillna(0).astype(int)

    # Cleanup columns
    final_cols = ['year', 'country1', 'isocode1', 'CCode1', 'country2', 'isocode2', 'CCode2', 'is_certified']
    skeleton = skeleton[final_cols]
    
    output_path = 'data/interim/skeleton_certifications.csv'
    skeleton.to_csv(output_path, index=False)
    print(f"Skeleton generated in {output_path}: {len(skeleton)} rows.")

if __name__ == "__main__":
    generate_skeleton()
