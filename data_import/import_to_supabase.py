import os
import csv
from supabase import create_client

# Supabase credentials
SUPABASE_URL = "https://waiwxzbhzaraouhxigus.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhaXd4emJoemFyYW91aHhpZ3VzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk1MDEzNTYsImV4cCI6MjA1NTA3NzM1Nn0.APCsn65wDv3JyOkihYGxi7aPLsCJrMHe_N1YI6L3wZ0"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def read_csv(filename):
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        return list(reader)

def import_data():
    # Import food data
    print("Importing food data...")
    food_data = read_csv('food_data.csv')
    for batch in [food_data[i:i+100] for i in range(0, len(food_data), 100)]:
        data = [{
            'fdc_id': int(row['fdc_id']),
            'description_en': row['description_en'],
            'description_de': row['description_de']
        } for row in batch]
        supabase.table('fdc_food').insert(data).execute()
    
    # Import portions data
    print("Importing portions data...")
    portions_data = read_csv('portions_data.csv')
    for batch in [portions_data[i:i+100] for i in range(0, len(portions_data), 100)]:
        data = [{
            'fdc_id': int(row['fdc_id']),
            'measure_unit_id': row['measure_unit_id'],
            'amount': float(row['amount']) if row['amount'] else 0,
            'gram_weight': float(row['gram_weight']) if row['gram_weight'] else 0
        } for row in batch]
        supabase.table('fdc_portions').insert(data).execute()
    
    # Import nutrients data
    print("Importing nutrients data...")
    nutrients_data = read_csv('nutrients_data.csv')
    for batch in [nutrients_data[i:i+100] for i in range(0, len(nutrients_data), 100)]:
        data = [{
            'fdc_id': int(row['fdc_id']),
            'nutrient_id': int(row['nutrient_id']),
            'amount': float(row['amount']) if row['amount'] else 0
        } for row in batch]
        supabase.table('fdc_nutrients').insert(data).execute()

if __name__ == "__main__":
    import_data()
    print("Data import complete!")
