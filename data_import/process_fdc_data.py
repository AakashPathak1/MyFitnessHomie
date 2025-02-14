import json
import requests
import csv
from typing import Dict, List
import os

# Your FDC API key
API_KEY = "swbOj18TO0nNbctot3D3fomPuqshJOGyOTmK5Qqo"

def fetch_food_data(page: int = 1, per_page: int = 200) -> Dict:
    url = f"https://api.nal.usda.gov/fdc/v1/foods/list"
    params = {
        "api_key": API_KEY,
        "pageSize": per_page,
        "pageNumber": page,
        "dataType": ["Foundation", "SR Legacy"]
    }
    response = requests.get(url, params=params)
    return response.json()

def process_foods(foods: List[Dict]) -> tuple:
    food_data = []
    portions_data = []
    nutrients_data = []
    
    for food in foods:
        fdc_id = food.get('fdcId')
        description = food.get('description', '')
        
        # Add to food table
        food_data.append({
            'fdc_id': fdc_id,
            'description_en': description,
            'description_de': ''  # Leave German translation empty for now
        })
        
        # Process portions
        for portion in food.get('foodPortions', []):
            portions_data.append({
                'fdc_id': fdc_id,
                'measure_unit_id': portion.get('measureUnit', ''),
                'amount': portion.get('amount', 0),
                'gram_weight': portion.get('gramWeight', 0)
            })
        
        # Process nutrients
        for nutrient in food.get('foodNutrients', []):
            nutrients_data.append({
                'fdc_id': fdc_id,
                'nutrient_id': nutrient.get('nutrientId', 0),
                'amount': nutrient.get('amount', 0)
            })
    
    return food_data, portions_data, nutrients_data

def write_to_csv(data: List[Dict], filename: str, fieldnames: List[str]):
    with open(filename, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)

def main():
    all_foods = []
    page = 1
    total_pages = 5  # Limit to 1000 foods for initial setup
    
    print("Fetching food data from USDA...")
    for page in range(1, total_pages + 1):
        print(f"Fetching page {page}/{total_pages}...")
        foods = fetch_food_data(page)
        all_foods.extend(foods)
    
    print("Processing data...")
    food_data, portions_data, nutrients_data = process_foods(all_foods)
    
    print("Writing to CSV files...")
    # Write food data
    write_to_csv(
        food_data,
        'food_data.csv',
        ['fdc_id', 'description_en', 'description_de']
    )
    
    # Write portions data
    write_to_csv(
        portions_data,
        'portions_data.csv',
        ['fdc_id', 'measure_unit_id', 'amount', 'gram_weight']
    )
    
    # Write nutrients data
    write_to_csv(
        nutrients_data,
        'nutrients_data.csv',
        ['fdc_id', 'nutrient_id', 'amount']
    )
    
    print("Done! CSV files have been created.")

if __name__ == "__main__":
    main()
