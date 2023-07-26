digits :: Integral t => t -> [t]
digits 0 = []
digits n = digits (div n 10) ++ [mod n 10]

isPalindrome :: Integral t => t -> Bool
isPalindrome n = d == reverse d where d = digits n

main :: IO()
main = print $ maximum $ filter isPalindrome [a * b | a <- [100..999], b <- [100..999]]
