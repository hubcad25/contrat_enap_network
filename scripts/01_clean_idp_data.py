
import pandas as pd
import zipfile
import os

def clean_idp_data():
    print("Cleaning IDP data from ZIP...")
    zip_path = 'data/raw/IDP_dataverse_files.zip'
    target_csv = 'IdealPointDyads1946-2025.csv'
    output_path = 'data/interim/idp_dyads_clean.csv'
    
    if not os.path.exists(zip_path):
        print(f"Error: {zip_path} not found.")
        return

    os.makedirs('data/interim', exist_ok=True)
    
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extract(target_csv, 'data/interim')
    
    temp_csv = os.path.join('data/interim', target_csv)
    
    # Use chunksize for memory efficiency if needed, but 1995+ should fit
    df = pd.read_csv(temp_csv)
    df = df[df['year'] >= 1995]
    
    # Save cleaned version
    df.to_csv(output_path, index=False)
    
    # Cleanup temp extraction
    os.remove(temp_csv)
    print(f"IDP data cleaned and saved to {output_path}")

if __name__ == "__main__":
    clean_idp_data()
