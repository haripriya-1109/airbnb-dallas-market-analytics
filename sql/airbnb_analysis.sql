/*
Airbnb Dallas Market & Operations Analytics
Tools: SQL Server
Dataset: Inside Airbnb - Dallas listings
*/

USE AirbnbAnalytics;
GO


/* =========================================================
   1. OVERALL MARKET OVERVIEW
   ========================================================= */

SELECT
    COUNT(*) AS total_listings,
    AVG(price) AS average_price,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,
    AVG(number_of_reviews) AS average_lifetime_reviews,
    AVG(availability_365) AS average_availability_days
FROM dbo.AirbnbListings;


/* =========================================================
   2. LISTINGS AND PRICING BY ROOM TYPE
   ========================================================= */

SELECT
    room_type,
    COUNT(*) AS listing_count,
    AVG(price) AS average_price,
    AVG(number_of_reviews) AS average_reviews,
    AVG(availability_365) AS average_availability
FROM dbo.AirbnbListings
GROUP BY room_type
ORDER BY listing_count DESC;


/* =========================================================
   3. NEIGHBORHOOD PRICING
   ========================================================= */

SELECT
    neighbourhood,
    COUNT(*) AS listing_count,
    AVG(price) AS average_price,
    AVG(number_of_reviews) AS average_reviews,
    AVG(availability_365) AS average_availability
FROM dbo.AirbnbListings
GROUP BY neighbourhood
HAVING COUNT(*) >= 100
ORDER BY average_price DESC;


/* =========================================================
   4. NEIGHBORHOOD PRICE VS. DALLAS MARKET AVERAGE
   ========================================================= */

WITH market AS (
    SELECT AVG(price) AS market_average_price
    FROM dbo.AirbnbListings
)
SELECT
    a.neighbourhood,
    COUNT(*) AS listing_count,
    AVG(a.price) AS average_price,
    AVG(a.price) - market.market_average_price
        AS difference_from_market
FROM dbo.AirbnbListings a
CROSS JOIN market
GROUP BY
    a.neighbourhood,
    market.market_average_price
HAVING COUNT(*) >= 100
ORDER BY difference_from_market DESC;


/* =========================================================
   5. MEDIAN PRICE BY NEIGHBORHOOD
   ========================================================= */

SELECT DISTINCT
    neighbourhood,
    COUNT(*) OVER (
        PARTITION BY neighbourhood
    ) AS listing_count,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price)
        OVER (PARTITION BY neighbourhood) AS median_price
FROM dbo.AirbnbListings
ORDER BY median_price DESC;


/* =========================================================
   6. HOST PORTFOLIO SEGMENTATION
   ========================================================= */

SELECT
    CASE
        WHEN calculated_host_listings_count = 1
            THEN 'Single-property host'
        WHEN calculated_host_listings_count >= 2
            THEN 'Multi-property host'
        ELSE 'Unknown'
    END AS host_segment,
    COUNT(*) AS listing_count,
    AVG(price) AS average_price,
    AVG(number_of_reviews) AS average_reviews,
    AVG(availability_365) AS average_availability
FROM dbo.AirbnbListings
GROUP BY
    CASE
        WHEN calculated_host_listings_count = 1
            THEN 'Single-property host'
        WHEN calculated_host_listings_count >= 2
            THEN 'Multi-property host'
        ELSE 'Unknown'
    END
ORDER BY listing_count DESC;


/* =========================================================
   7. HOST SUPPLY CONCENTRATION
   ========================================================= */

SELECT
    CASE
        WHEN calculated_host_listings_count = 1
            THEN 'Single-property host'
        WHEN calculated_host_listings_count >= 2
            THEN 'Multi-property host'
        ELSE 'Unknown'
    END AS host_segment,
    COUNT(*) AS listing_count,
    COUNT(DISTINCT host_id) AS unique_hosts,
    CAST(
        100.0 * COUNT(*) /
        NULLIF(
            SUM(
                CASE
                    WHEN calculated_host_listings_count IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ) OVER (),
            0
        )
        AS DECIMAL(5,2)
    ) AS percent_of_known_host_supply
FROM dbo.AirbnbListings
GROUP BY
    CASE
        WHEN calculated_host_listings_count = 1
            THEN 'Single-property host'
        WHEN calculated_host_listings_count >= 2
            THEN 'Multi-property host'
        ELSE 'Unknown'
    END
ORDER BY listing_count DESC;


/* =========================================================
   8. RECENT GUEST ACTIVITY BY NEIGHBORHOOD
   Reviews in the last 12 months are used as a
   proxy for recent customer activity.
   ========================================================= */

SELECT
    neighbourhood,
    COUNT(*) AS listing_count,
    AVG(price) AS average_price,
    AVG(number_of_reviews_ltm) AS average_recent_reviews,
    AVG(availability_365) AS average_availability
FROM dbo.AirbnbListings
GROUP BY neighbourhood
HAVING COUNT(*) >= 100
ORDER BY average_recent_reviews DESC;


/* =========================================================
   9. PRICE SEGMENT DISTRIBUTION
   ========================================================= */

SELECT
    CASE
        WHEN price < 150 THEN 'Budget'
        WHEN price < 300 THEN 'Mid-range'
        WHEN price < 600 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_segment,
    COUNT(*) AS listing_count,
    AVG(price) AS average_price,
    AVG(number_of_reviews_ltm) AS average_recent_reviews
FROM dbo.AirbnbListings
GROUP BY
    CASE
        WHEN price < 150 THEN 'Budget'
        WHEN price < 300 THEN 'Mid-range'
        WHEN price < 600 THEN 'Premium'
        ELSE 'Luxury'
    END
ORDER BY listing_count DESC;


/* =========================================================
   10. PRICE SEGMENT BY ROOM TYPE
   ========================================================= */

SELECT
    room_type,
    CASE
        WHEN price < 150 THEN 'Budget'
        WHEN price < 300 THEN 'Mid-range'
        WHEN price < 600 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_segment,
    COUNT(*) AS listing_count
FROM dbo.AirbnbListings
GROUP BY
    room_type,
    CASE
        WHEN price < 150 THEN 'Budget'
        WHEN price < 300 THEN 'Mid-range'
        WHEN price < 600 THEN 'Premium'
        ELSE 'Luxury'
    END
ORDER BY room_type, listing_count DESC;


/* =========================================================
   11. LUXURY VS. NON-LUXURY
   ========================================================= */

SELECT
    CASE
        WHEN price >= 600 THEN 'Luxury'
        ELSE 'Non-Luxury'
    END AS luxury_category,
    COUNT(*) AS listing_count,
    AVG(price) AS average_price,
    AVG(number_of_reviews_ltm) AS average_recent_reviews,
    AVG(availability_365) AS average_availability,
    AVG(minimum_nights) AS average_minimum_nights
FROM dbo.AirbnbListings
GROUP BY
    CASE
        WHEN price >= 600 THEN 'Luxury'
        ELSE 'Non-Luxury'
    END
ORDER BY average_price DESC;


/* =========================================================
   12. PREMIUM LISTINGS WITH HIGH RECENT ACTIVITY
   ========================================================= */

SELECT TOP 20
    id,
    name,
    neighbourhood,
    room_type,
    price,
    number_of_reviews_ltm,
    availability_365,
    minimum_nights
FROM dbo.AirbnbListings
WHERE price >= 600
  AND number_of_reviews_ltm >= 20
  AND is_price_outlier = 0
ORDER BY number_of_reviews_ltm DESC;


/* =========================================================
   13. TOP 3 MOST ACTIVE LISTINGS IN EACH NEIGHBORHOOD
   ========================================================= */

WITH ranked_listings AS (
    SELECT
        id,
        name,
        neighbourhood,
        room_type,
        price,
        number_of_reviews_ltm,
        availability_365,
        RANK() OVER (
            PARTITION BY neighbourhood
            ORDER BY number_of_reviews_ltm DESC
        ) AS activity_rank
    FROM dbo.AirbnbListings
)
SELECT
    id,
    name,
    neighbourhood,
    room_type,
    price,
    number_of_reviews_ltm,
    availability_365,
    activity_rank
FROM ranked_listings
WHERE activity_rank <= 3
ORDER BY neighbourhood, activity_rank;


/* =========================================================
   14. PRICE OUTLIER SUMMARY
   ========================================================= */

SELECT
    is_price_outlier,
    COUNT(*) AS listing_count,
    AVG(price) AS average_price,
    MAX(price) AS maximum_price
FROM dbo.AirbnbListings
GROUP BY is_price_outlier
ORDER BY is_price_outlier;
