main :: IO()
main = print $ head [n | n <- [1..], sum [mod n d | d <- [2..20]] == 0]
