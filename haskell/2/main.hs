fibonacci :: Integer -> Integer
fibonacci 1 = 1
fibonacci 2 = 2
fibonacci n = fibonacci (n - 1) + fibonacci (n - 2)

sumOfEvenFibBelow :: Integer -> Integer
sumOfEvenFibBelow n = sum $ filter (\x -> mod x 2 == 0) $ takeWhile (<n) $ map fibonacci [1..]

main :: IO()
main = print $ sumOfEvenFibBelow 4000000
