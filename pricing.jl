using DataStructures

struct Label
    rcost::Float64 # less is better
    weight::Int64 # current weight
    last_item_added::Int # item added in this label
    # prev_lab::Vector{Label} # last label
    items::BitVector # items in the bin so far
    conflicts::BitVector # conflics that will be found by moving forward

end

"Returns true if l1 dominates l2"
function Base.isless(l1::Label, l2::Label)

    # l1 dominates l2 if:
    #   the possibilities set of l1 *at least contains* the possibilities set of l2
    #   l1 has smaller reduced cost

    if l1.weight <= l2.weight
        if l1.rcost <= l2.rcost
            return all(l1.conflicts .<= l2.conflicts)
        else
            return false
        end
    else
        return false
    end
end

function dp_price(J, len_J, rc, positive_rcost, w, binarized_E, W; verbose=3, epsilon=1e-4)

    buckets = Vector{Label}[Label[] for i in J]

    to_extend = BinaryMinHeap{Label}()
    for i in 1:len_J
        if !positive_rcost[i]
            continue
        end

        # label = Label(rc[i], w[i], i, Label[], deepcopy(binarized_E[i][i+1:end]))
        # label = Label(1-rc[i], w[i], i, Label[], deepcopy(binarized_E[i]))
        label = Label(1-rc[i], w[i], i, falses(len_J), deepcopy(binarized_E[i]))
        label.items[i] = true

        push!(buckets[i], label)

        if i < len_J
            push!(to_extend, label)
        end
    end

    trash = Dict{Label, Nothing}()
    # println("starting extensions")
    while !isempty(to_extend)

        # println(to_extend)

        curr_label = pop!(to_extend)

        # println(curr_label)

        # if the label is marked for deletion, delete and continue
        if haskey(trash, curr_label)
            delete!(trash, curr_label)
            continue
        end

        for i in curr_label.last_item_added+1:len_J

            # if the item has negative reduced cost, skip it
            if !positive_rcost[i]
                continue
            end

            # if the item is in conflict with the label, skip it
            if curr_label.conflicts[i]
                continue
            end

            new_weight = curr_label.weight + w[i]
            if new_weight > W
                continue
            end

            # println("here")
            # new_next_conflicts =  curr_label.conflicts[i-curr_label.last_item_added+1:end] .|| binarized_E[i][i+1:end]
            new_next_conflicts = deepcopy(curr_label.conflicts)
            new_next_conflicts[i+1:end] =  curr_label.conflicts[i+1:end] .|| binarized_E[i][i+1:end]
            # println(new_next_conflicts)

            new_label = Label(
                curr_label.rcost - rc[i], 
                new_weight, 
                i, 
                # Label[curr_label], 
                deepcopy(curr_label.items), 
                new_next_conflicts,
                # curr_label.conflicts[i-curr_label.last_item_added+1:end] .|| binarized_E[i+1:end],
            )

            new_label.items[i] = true



            # check for domination
            dominated = Dict{Label, Nothing}()
            clean_bucket = false
            clean_matrix = false
            new_label_is_dominated = false
            for label in buckets[i]
                
                # is the new label dominated?
                if label < new_label    
                    new_label_is_dominated = true
                    break
                end

                # does the new label dominate any label?
                if new_label < label

                    # add dominated to trash
                    trash[label] = nothing

                    # register dominated for later deletion
                    dominated[label] = nothing
                    clean_matrix = true
                end
            end

            # remove the labels dominated by the new label, if necessary
            if clean_matrix
                deleteat!(buckets[i], findall(x -> x in keys(dominated), buckets[i]))
            end

            if new_label_is_dominated
                continue
            else # if the new label isn't dominated
                push!(buckets[i], new_label)
                push!(to_extend, new_label)
                # println(new_label)
            end 
        end
    end

    min_rcost = Inf
    best_label = nothing
    for bucket in buckets
        for label in bucket
            if label.rcost < min_rcost
                min_rcost = label.rcost
                best_label = label
            end
        end
    end

    # println("best label: ", best_label)

    # new_bin = falses(len_J)
    # if min_rcost < -epsilon && min_rcost < Inf
    #     label = best_label
        
    #     done = false
    #     while !done
    #         new_bin[label.last_item_added] = true
    #         if isempty(label.prev_lab) # is this the last label?
    #             done = true
    #         else
    #             label = label.prev_lab[1]
    #         end
    #     end
    # end
    println("new_bin: $(best_label.items)")
    return min_rcost, best_label.items
end


# # base data
# len_J = 10
# J = [i for i in 1:len_J]

# # reduced costs
# # rc = [i for i in J]
# rc = rand(-10:10, 10)

# positive_rcost = Bool[i > 0 for i in rc]

# w = [i*10 for i in J]
# W = 120

# translated_E = []
# for k in 1:rand(1:len_J*(len_J-1)/2)
#     i = rand(1:len_J-1)
#     j = rand(i+1:len_J)
#     push!(translated_E, [i,j])
# end
# sort!(translated_E)

# println(translated_E)
# println(rc)

# # binarized_E[i][j] = 1 if (i, j) ∈ E
# # binarized_E = Vector{Int64}[Int64[0 for j in 1:len_J] for i in 1:len_J]
# # binarized_E = BitVector[BitVector(undef, len_J) for i in J]
# binarized_E = BitVector[falses(len_J) for i in J]

# for i in J
#     binarized_E[i] .= false
# end

# for (i, j) in translated_E
#     binarized_E[i][j] = true
#     binarized_E[j][i] = true
# end

# min_rcost, new_bin = dp_price(J, len_J, rc, positive_rcost, w, binarized_E, translated_E, W)

# println(min_rcost)
# println(new_bin)




