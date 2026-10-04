primes :: [Integer]
primes = 2 : filterPrime [3, 5 ..] where filterPrime (p : xs) = p : filterPrime [x | x <- xs, mod x p /= 0]

primeFactors :: Integer -> [Integer]
primeFactors 1 = []
primeFactors n | n > 1, p : _ <- filter (\x -> mod n x == 0) primes = p : primeFactors (div n p) | otherwise = []

main :: IO ()
main = print $ last $ primeFactors 600851475143
