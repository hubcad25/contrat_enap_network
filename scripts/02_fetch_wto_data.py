
import pandas as pd
import zipfile
import os

def process_wto_data():
    print("Starting WTO data processing...")
    
    # Path configuration
    bpm5_zip = 'data/raw/OECD-WTO_BATIS_data.zip'
    bpm6_zip = 'data/raw/OECD-WTO_BATIS_data_BPM6-1.zip'
    output_path = 'data/interim/wto_digital_services.csv'
    
    # Ferracane 2024 / EBOPS Definitions
    # BPM5 (EBOPS 2002) - Digitally Deliverable Services
    digital_codes_bpm5 = ['S245', 'S253', 'S260', 'S262', 'S266', 'S268', 'S287']
    total_code_bpm5 = 'S200'
    
    # BPM6 (EBOPS 2010) - Digitally Deliverable Services
    digital_codes_bpm6 = ['SF', 'SG', 'SH', 'SI', 'SJ', 'SK']
    total_code_bpm6 = 'S'
    
    os.makedirs('data/interim', exist_ok=True)
    
    # ISO-2 to ISO-3 mapping (Common countries in BaTiS)
    iso2_to_iso3 = {
        'AD': 'AND', 'AE': 'ARE', 'AF': 'AFG', 'AG': 'ATG', 'AI': 'AIA', 'AL': 'ALB', 'AM': 'ARM', 'AO': 'AGO',
        'AQ': 'ATA', 'AR': 'ARG', 'AS': 'ASM', 'AT': 'AUT', 'AU': 'AUS', 'AW': 'ABW', 'AX': 'ALA', 'AZ': 'AZE',
        'BA': 'BIH', 'BB': 'BRB', 'BD': 'BGD', 'BE': 'BEL', 'BF': 'BFA', 'BG': 'BGR', 'BH': 'BHR', 'BI': 'BDI',
        'BJ': 'BEN', 'BL': 'BLM', 'BM': 'BMU', 'BN': 'BRN', 'BO': 'BOL', 'BQ': 'BES', 'BR': 'BRA', 'BS': 'BHS',
        'BT': 'BTN', 'BV': 'BVT', 'BW': 'BWA', 'BY': 'BLR', 'BZ': 'BLZ', 'CA': 'CAN', 'CC': 'CCK', 'CD': 'COD',
        'CF': 'CAF', 'CG': 'COG', 'CH': 'CHE', 'CI': 'CIV', 'CK': 'COK', 'CL': 'CHL', 'CM': 'CMR', 'CN': 'CHN',
        'CO': 'COL', 'CR': 'CRI', 'CU': 'CUB', 'CV': 'CPV', 'CW': 'CUW', 'CX': 'CXR', 'CY': 'CYP', 'CZ': 'CZE',
        'DE': 'DEU', 'DJ': 'DJI', 'DK': 'DNK', 'DM': 'DMA', 'DO': 'DOM', 'DZ': 'DZA', 'EC': 'ECU', 'EE': 'EST',
        'EG': 'EGY', 'EH': 'ESH', 'ER': 'ERI', 'ES': 'ESP', 'ET': 'ETH', 'FI': 'FIN', 'FJ': 'FJI', 'FK': 'FLK',
        'FM': 'FSM', 'FO': 'FRO', 'FR': 'FRA', 'GA': 'GAB', 'GB': 'GBR', 'GD': 'GRD', 'GE': 'GEO', 'GF': 'GUF',
        'GG': 'GGY', 'GH': 'GHA', 'GI': 'GIB', 'GL': 'GRL', 'GM': 'GMB', 'GN': 'GIN', 'GP': 'GLP', 'GQ': 'GNQ',
        'GR': 'GRC', 'GS': 'SGS', 'GT': 'GTM', 'GU': 'GUM', 'GW': 'GNB', 'GY': 'GUY', 'HK': 'HKG', 'HM': 'HMD',
        'HN': 'HND', 'HR': 'HRV', 'HT': 'HTI', 'HU': 'HUN', 'ID': 'IDN', 'IE': 'IRL', 'IL': 'ISR', 'IM': 'IMN',
        'IN': 'IND', 'IO': 'IOT', 'IQ': 'IRQ', 'IR': 'IRN', 'IS': 'ISL', 'IT': 'ITA', 'JE': 'JEY', 'JM': 'JAM',
        'JO': 'JOR', 'JP': 'JPN', 'KE': 'KEN', 'KG': 'KGZ', 'KH': 'KHM', 'KI': 'KIR', 'KM': 'COM', 'KN': 'KNA',
        'KP': 'PRK', 'KR': 'KOR', 'KW': 'KWT', 'KY': 'CYM', 'KZ': 'KAZ', 'LA': 'LAO', 'LB': 'LBN', 'LC': 'LCA',
        'LI': 'LIE', 'LK': 'LKA', 'LR': 'LBR', 'LS': 'LSO', 'LT': 'LTU', 'LU': 'LUX', 'LV': 'LVA', 'LY': 'LBY',
        'MA': 'MAR', 'MC': 'MCO', 'MD': 'MDA', 'ME': 'MNE', 'MF': 'MAF', 'MG': 'MDG', 'MH': 'MHL', 'MK': 'MKD',
        'ML': 'MLI', 'MM': 'MMR', 'MN': 'MNG', 'MO': 'MAC', 'MP': 'MNP', 'MQ': 'MTQ', 'MR': 'MRT', 'MS': 'MSR',
        'MT': 'MLT', 'MU': 'MUS', 'MV': 'MDV', 'MW': 'MWI', 'MX': 'MEX', 'MY': 'MYS', 'MZ': 'MOZ', 'NA': 'NAM',
        'NC': 'NCL', 'NE': 'NER', 'NF': 'NFK', 'NG': 'NGA', 'NI': 'NIC', 'NL': 'NLD', 'NO': 'NOR', 'NP': 'NPL',
        'NR': 'NRU', 'NU': 'NIU', 'NZ': 'NZL', 'OM': 'OMN', 'PA': 'PAN', 'PE': 'PER', 'PF': 'PYF', 'PG': 'PNG',
        'PH': 'PHL', 'PK': 'PAK', 'PL': 'POL', 'PM': 'SPM', 'PN': 'PCN', 'PR': 'PRI', 'PS': 'PSE', 'PT': 'PRT',
        'PW': 'PLW', 'PY': 'PRY', 'QA': 'QAT', 'RE': 'REU', 'RO': 'ROU', 'RS': 'SRB', 'RU': 'RUS', 'RW': 'RWA',
        'SA': 'SAU', 'SB': 'SLB', 'SC': 'SYC', 'SD': 'SDN', 'SE': 'SWE', 'SG': 'SGP', 'SH': 'SHN', 'SI': 'SVN',
        'SJ': 'SJM', 'SK': 'SVK', 'SL': 'SLE', 'SM': 'SMR', 'SN': 'SEN', 'SO': 'SOM', 'SR': 'SUR', 'SS': 'SSD',
        'ST': 'STP', 'SV': 'SLV', 'SX': 'SXM', 'SY': 'SYR', 'SZ': 'SWZ', 'TC': 'TCA', 'TD': 'TCD', 'TF': 'ATF',
        'TG': 'TGO', 'TH': 'THA', 'TJ': 'TJK', 'TK': 'TKL', 'TL': 'TLS', 'TM': 'TKM', 'TN': 'TUN', 'TO': 'TON',
        'TR': 'TUR', 'TT': 'TTO', 'TV': 'TUV', 'TW': 'TWN', 'TZ': 'TZA', 'UA': 'UKR', 'UG': 'UGA', 'UM': 'UMI',
        'US': 'USA', 'UY': 'URY', 'UZ': 'UZB', 'VA': 'VAT', 'VC': 'VCT', 'VE': 'VEN', 'VG': 'VGB', 'VI': 'VIR',
        'VN': 'VNM', 'VU': 'VUT', 'WF': 'WLF', 'WS': 'WSM', 'YE': 'YEM', 'YT': 'MYT', 'ZA': 'ZAF', 'ZM': 'ZMB',
        'ZW': 'ZWE'
    }

    def process_file(zip_path, filename, digital_codes, total_code, year_range):
        print(f"Reading {zip_path}...")
        df_list = []
        if not os.path.exists(zip_path):
            print(f"Warning: {zip_path} not found.")
            return pd.DataFrame()
            
        with zipfile.ZipFile(zip_path, 'r') as z:
            with z.open(filename) as f:
                # Use chunks to save memory
                chunk_iter = pd.read_csv(f, chunksize=1000000, dtype={'Reporter': str, 'Partner': str, 'Item_code': str})
                for chunk in chunk_iter:
                    # Filter years and flows
                    chunk = chunk[(chunk['Year'].isin(year_range)) & (chunk['Flow'].isin(['X', 'M']))]
                    # Filter items
                    mask = chunk['Item_code'].isin(digital_codes + [total_code])
                    chunk = chunk[mask]
                    
                    if not chunk.empty:
                        df_list.append(chunk)
        
        if not df_list:
            return pd.DataFrame()
            
        df = pd.concat(df_list)
        df['is_digital'] = df['Item_code'].isin(digital_codes)
        
        # Aggregate by dyad
        # digital
        digital = df[df['is_digital']].groupby(['Reporter', 'Partner', 'Year', 'Flow'])['Balanced_value'].sum().reset_index()
        digital.rename(columns={'Balanced_value': 'digital_value'}, inplace=True)
        
        # total
        total = df[df['Item_code'] == total_code].groupby(['Reporter', 'Partner', 'Year', 'Flow'])['Balanced_value'].sum().reset_index()
        total.rename(columns={'Balanced_value': 'total_value'}, inplace=True)
        
        return pd.merge(total, digital, on=['Reporter', 'Partner', 'Year', 'Flow'], how='outer').fillna(0)

    all_data = []

    # 1. Process BPM5 (1995-2004)
    df5 = process_file(bpm5_zip, 'OECD-WTO_BATIS_data.csv', digital_codes_bpm5, total_code_bpm5, range(1995, 2005))
    if not df5.empty:
        all_data.append(df5)
    
    # 2. Process BPM6 (2005-2023)
    df6 = process_file(bpm6_zip, 'OECD-WTO_BATIS_BPM6_December2025_bulk.csv', digital_codes_bpm6, total_code_bpm6, range(2005, 2025))
    if not df6.empty:
        all_data.append(df6)

    if not all_data:
        print("No data processed.")
        return

    combined = pd.concat(all_data)
    
    # Map ISO-2 to ISO-3
    combined['isocode1'] = combined['Reporter'].map(iso2_to_iso3)
    combined['isocode2'] = combined['Partner'].map(iso2_to_iso3)
    
    # Filter out rows where mapping failed (World, regions, etc.)
    final_wto = combined.dropna(subset=['isocode1', 'isocode2']).copy()
    
    # Standardize columns
    final_wto = final_wto[['Year', 'isocode1', 'isocode2', 'Flow', 'total_value', 'digital_value']]
    final_wto.rename(columns={'Year': 'year'}, inplace=True)
    
    # Save to interim
    final_wto.to_csv(output_path, index=False)
    print(f"WTO data saved to {output_path}. Rows: {len(final_wto)}")

if __name__ == "__main__":
    process_wto_data()
