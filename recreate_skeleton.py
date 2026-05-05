
import pandas as pd
import numpy as np

# Load sources
attr = pd.read_excel('data/raw/structure/attribute.xlsx')
cow = pd.read_csv('data/raw/COW-country-codes.csv')
certif = pd.read_excel('data/raw/Data.xlsx', header=0)
certif.columns = ['Certifier', 'Certified', 'Year']

# Standardize COW codes mapping
# We need to map countries in attr to COW codes.
# Let's try to join on country name.
attr_countries = attr[['country', 'isocode']].drop_duplicates()
cow_map = cow[['StateNme', 'CCode']].drop_duplicates()

# Merge to get ccode for each country in attr
mapping = pd.merge(attr_countries, cow_map, left_on='country', right_on='StateNme', how='left')

# Check for missing COW codes
missing = mapping[mapping['CCode'].isna()]
if not missing.empty:
    print("Missing COW codes for:")
    print(missing['country'].unique())

# Manual mapping for common mismatches if needed (optional for now, let's see output)

# Generate Skeleton
years = sorted(attr['year'].unique())
countries = mapping.dropna(subset=['CCode'])

skeleton_list = []
for year in years:
    # Filter countries available in that year from attr
    year_countries = attr[attr['year'] == year][['country', 'isocode']]
    year_mapping = pd.merge(year_countries, mapping, on=['country', 'isocode'])
    
    # Create cross product
    nodes = year_mapping[['country', 'isocode', 'CCode']].dropna()
    nodes['key'] = 1
    dyads = pd.merge(nodes, nodes, on='key', suffixes=('1', '2'))
    dyads = dyads[dyads['country1'] != dyads['country2']]
    dyads['year'] = year
    skeleton_list.append(dyads.drop('key', axis=1))

skeleton = pd.concat(skeleton_list)

# Join with Certifications
# Standardize names in certif to match attr if possible
# Or join on names and handle mismatches
certif['is_certified'] = 1

# Note: Data.xlsx names might differ. Let's do a fuzzy or direct match check.
skeleton = pd.merge(
    skeleton, 
    certif, 
    left_on=['country1', 'country2', 'year'], 
    right_on=['Certifier', 'Certified', 'Year'], 
    how='left'
)
skeleton['is_certified'] = skeleton['is_certified'].fillna(0).astype(int)

# Cleanup
skeleton = skeleton[['year', 'country1', 'isocode1', 'CCode1', 'country2', 'isocode2', 'CCode2', 'is_certified']]

# Export
skeleton.to_csv('data/interim/skeleton_certifications.csv', index=False)
print(f"Skeleton generated: {len(skeleton)} rows.")
