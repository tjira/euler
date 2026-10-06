function main()
    total = 0

    for i = 1:999
        if i % 3 == 0 || i % 5 == 0
            total += i
        end
    end

    println(total)
end

main()
