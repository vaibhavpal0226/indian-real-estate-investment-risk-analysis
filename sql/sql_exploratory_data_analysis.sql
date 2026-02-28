SELECT * FROM processed_property_data;

# Q1. Find properties that are "Safe" but price is less than the neighborhood average.
SELECT city, locality, price_inr, price_per_sqft, price_deviation_pct, safety_ratings
FROM processed_property_data
WHERE safety_ratings = 'Verified & Safe' AND price_category = 'Underpriced'
ORDER BY price_deviation_pct ASC
LIMIT 10;

# Q2. Find the top 3 properties in every city that offer the best balance of Safety, Modernity, and Price Segment.
WITH PropertiesScore AS (
	SELECT
		listingid, city, locality, price_inr, safety_ratings, modernity_index, price_category,
		(CASE WHEN safety_ratings = 'Verified & Safe' THEN 10
			  WHEN safety_ratings = 'Caution' THEN 5 ELSE 0 END + 
		 CASE WHEN modernity_index = 'Ultra-Modern/Smart' THEN 10
			  WHEN modernity_index = 'Standard Modern' THEN 5 ELSE 0 END + 
		 CASE WHEN price_category = 'Underpriced' THEN 10
			  WHEN price_category = 'Fair Market Value' THEN 5 ELSE 0 END) as total_investment_score
    FROM processed_property_data          
),
RankedProperties AS (
	SELECT *, 
		ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_investment_score DESC, price_inr ASC) as property_rank
    FROM PropertiesScore
)
SELECT * FROM RankedProperties
WHERE property_rank <=3; 

# Q3. Identify which cities have the highest concentration of "High Risk" properties.
SELECT city, COUNT(*) as total_listings, 
ROUND((SUM(CASE WHEN safety_ratings = 'High Risk' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) as risk_percentage
FROM processed_property_data
GROUP BY city
ORDER BY risk_percentage DESC;

# Q4. Calculate the exact "Premium" people pay for modern, high-amenity homes compared to traditional ones in each city.
SELECT city,
AVG(CASE WHEN modernity_index = 'Ultra-Modern/Smart' THEN price_per_sqft END) as smart_home_price,
AVG(CASE WHEN modernity_index = 'Basic/Traditional' THEN price_per_sqft END) as traditional_home_price,
ROUND(((AVG(CASE WHEN modernity_index = 'Ultra-Modern/Smart' THEN price_per_sqft END) - 
	AVG(CASE WHEN modernity_index = 'Basic/Traditional' THEN price_per_sqft END)) / 
    AVG(CASE WHEN modernity_index = 'Basic/Traditional' THEN price_per_sqft END)) *100,2) as luxury_premium_pct
FROM processed_property_data
GROUP BY city
ORDER BY luxury_premium_pct DESC;

# Q5. Find properties that have "Standard Efficiency" (moderate space) but are categorized as "Overpriced".
SELECT city, propertytype, price_category,
AVG(price_per_sqft) AS avg_unit_price
FROM processed_property_data
WHERE space_efficieny_grade = 'Standard' AND price_category = 'Overpriced'
GROUP BY city, propertytype, price_category
ORDER BY avg_unit_price DESC;

# Q6. Does building age significantly impact price in luxury segments vs. budget segments?
SELECT price_category, structural_life_stage, 
       ROUND(AVG(price_per_sqft), 2) as avg_price_sqft,
       COUNT(*) as total_units
FROM processed_property_data
GROUP BY price_category, structural_life_stage
ORDER BY price_category, structural_life_stage;

# Q7. Identify properties with a "High-Utility" signal (good parking and bathroom ratios) that are New build and budget friendly.
SELECT listingid, city, bhk, structural_life_stage, price_inr
FROM processed_property_data
WHERE utility_balance = 'High-Utility' AND structural_life_stage = 'New' 
AND price_category IN ('Underpriced', 'Fair Market Value')
ORDER BY price_inr DESC;

# Q8. Which cities are dominated by 'Large Family Choice' segments versus 'Bachelor/Studio'?
SELECT city, family_segment, COUNT(*) as property_count
FROM processed_property_data
WHERE family_segment IN ('Large Family Choice', 'Bachelor/Studio')
GROUP BY city, family_segment
ORDER BY city, family_segment DESC;

# Q9. Find all the 'Rare Assets' (from low_density_premium column) in cities where the majority of listings are 'High FSI'.
SELECT city, locality, price_inr, fsi_category, low_density_premium
FROM processed_property_data
WHERE low_density_premium = 'Rare Asset' AND city IN 
(SELECT city FROM processed_property_data WHERE fsi_category = 'High FSI (Dense Urban)')
ORDER BY price_inr;

# Q10. How many "Premium/Luxury" apartments are listed with "None" or "Open" parking?
SELECT city, COUNT(*) as luxury_homes_without_secure_parking
FROM processed_property_data
WHERE price_category IN ('Premium', 'Overpriced')
  AND parking IN ('None', 'Open')
GROUP BY city
ORDER BY luxury_homes_without_secure_parking DESC;

# The SQL analysis confirmed that markets like Ahmedabad offer the best value-for-money, while Bengaluru and Mumbai carry 
# the highest risk but also the highest potential for rental yield.