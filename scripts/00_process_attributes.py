
import pandas as pd
import os

def process_attributes():
    print("Processing attributes from Data_localization.xlsx...")
    input_path = 'data/raw/Data_localization.xlsx'
    output_path = 'data/raw/structure/attribute.xlsx'
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return

    df = pd.read_excel(input_path)
    # Filter from 1995 as per doc.md
    df = df[df['year'] >= 1995]

    def get_model(row):
        if row['comp_local'] == 1:
            return 'localization'
        elif row['comp_safeharbor'] == 1:
            return 'safe harbor'
        else:
            return 'open'

    df['model'] = df.apply(get_model, axis=1)
    
    # Keep requested columns
    df = df[['year', 'country', 'isocode', 'model']]
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    df.to_excel(output_path, index=False)
    print(f"Attributes saved to {output_path}")

if __name__ == "__main__":
    process_attributes()
