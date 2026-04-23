import pandas as pd
import numpy as np
from sqlalchemy import create_engine

df = pd.read_csv("cleaned_vestiaire.csv")
df.replace([np.inf, -np.inf], None, inplace=True)
engine = create_engine("mysql+pymysql://root:Dwaraka#18@localhost/ecommerce_sql")
chunksize = 50000  

df.to_sql("e_data", con=engine, if_exists="append", index=False)



products = df[['product_id','product_name','product_type',
               'product_category','product_gender_target',
               'brand_id','brand_name','price_usd']].drop_duplicates()

products.to_sql("products", con=engine, if_exists="replace", index=False)

sellers = df[['seller_id','seller_username','seller_country',
              'seller_pass_rate','seller_num_followers',
              'seller_community_rank']].drop_duplicates()


sellers = sellers.sort_values('seller_id').drop_duplicates(subset='seller_id', keep='first')

sellers.to_sql("sellers", con=engine, if_exists="replace", index=False)


orders = df[['product_id','seller_id','sold',
             'price_usd','shipping_days','conversion_rate']]

orders.to_sql("orders", con=engine, if_exists="replace", index=False)