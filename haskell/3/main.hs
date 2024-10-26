primes :: [Integer]
primes = 2 : filterPrime [3,5..] where filterPrime (p:xs) = p : filterPrime [x | x <- xs, mod x p /= 0]

primeFactors :: Integer -> [Integer]
primeFactors 1 = []
primeFactors n = p : primeFactors (div n p) where p = head $ filter (\x -> mod n x == 0) primes

main :: IO()
main = print $ last $ primeFactors 600851475143
