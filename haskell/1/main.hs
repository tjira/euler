sumOfMultiplesBelow :: Integer -> Integer
sumOfMultiplesBelow n = sum [i | i <- [3..n-1], mod i 3 == 0 || mod i 5 == 0]

main :: IO()
main = print $ sumOfMultiplesBelow 1000
