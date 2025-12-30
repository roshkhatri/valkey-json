# JSON.MERGE Time Complexity

## Overview
The `JSON.MERGE` command has been optimized to achieve **O(M+N)** time complexity for merging operations.

## Complexity Analysis

### Single Path Evaluation
**When the path evaluates to a single value:**

**Time Complexity: O(M + N)**
- **M** = Size (number of nodes/elements) of the original value at the matched path (if it exists)
- **N** = Size (number of nodes/elements) of the new value being merged

**Explanation:**
- The merge algorithm performs a single pass through both the original and new JSON structures
- Each node in the original value is visited once: **O(M)**
- Each node in the new value is visited once: **O(N)**
- Key lookups in objects use hash-based member search: **O(1)** average
- Total: **O(M + N)**

### Multiple Path Evaluation (Wildcards)
**When the path evaluates to multiple values (e.g., using `$..field`):**

**Time Complexity: O(P × (M_avg + N))**
- **P** = Number of paths matched by the JSONPath expression
- **M_avg** = Average size of the original values at each matched location
- **N** = Size of the new value being merged

**Total work: O(M_total + P × N)**
- **M_total** = Total size of all matched original values = P × M_avg
- Each of the P matches performs an independent merge operation
- Result: **O(M_total + P × N)**

### Path Evaluation Cost
The JSONPath evaluation itself has complexity:
- **Simple path** (e.g., `.user.profile`): **O(D)** where D is path depth
- **Wildcard path** (e.g., `$.*` or `$..field`): **O(K)** where K is total document size

## Examples

### Example 1: Single Simple Path
```
JSON.MERGE key .user.profile {"age": 31, "city": "NYC"}
```
- Original at `.user.profile`: `{"name": "John", "age": 30}` → M = 3 nodes
- New value: `{"age": 31, "city": "NYC"}` → N = 3 nodes
- **Complexity: O(3 + 3) = O(6) = O(M + N)**

### Example 2: Nested Object Merge
```
JSON.MERGE key . {"user": {"profile": {"age": 31}}}
```
- Original: `{"user": {"profile": {"name": "John", "age": 30}, "id": 1}}` → M = 6 nodes
- New: `{"user": {"profile": {"age": 31}}}` → N = 4 nodes
- **Complexity: O(6 + 4) = O(10) = O(M + N)**

### Example 3: Multiple Path Matches
```
JSON.MERGE key $..user {"status": "active"}
```
- Matches 3 locations, each with average M_avg = 5 nodes
- New value: N = 2 nodes
- **Complexity: O(3 × 5 + 3 × 2) = O(15 + 6) = O(21)**
- **General form: O(M_total + P × N) where M_total = 15, P = 3, N = 2**

## Implementation Details

### Merge Algorithm (merge_values function)
```cpp
// Two-pass algorithm ensures O(M + N) complexity:

// Pass 1: Process existing members (M nodes)
for each key in existing_object:           // O(M) iterations
    lookup key in new_object               // O(1) average (hash-based)
    if both are objects: recursive merge   // Recurses on sub-trees
    else: use new value or keep existing   // O(1)

// Pass 2: Add new members (N nodes)  
for each key in new_object:                // O(N) iterations
    if not in merged: add it               // O(1) check and insert

// Total: O(M) + O(N) = O(M + N)
```

### Space Complexity
- **O(M + N)** for constructing the merged result
- Recursive depth limited to 100 levels: **O(1)** stack space

## Performance Characteristics

1. **Linear scaling**: Merge time scales linearly with input sizes
2. **Efficient key lookups**: RapidJSON's hash-based member access provides O(1) average lookup
3. **Single-pass traversal**: Each node visited exactly once
4. **Null optimization**: Keys with null values are skipped (no allocation)
5. **Depth limit**: Maximum recursion depth of 100 prevents stack overflow

## Comparison with Alternatives

| Approach | Complexity | Notes |
|----------|-----------|-------|
| **Current (optimized)** | **O(M + N)** | Single pass through both trees |
| Naive nested iteration | O(M × N) | Would compare every pair of keys |
| Full serialize/deserialize | O(M + N + output) | Additional overhead for string conversion |

## Worst-Case Scenarios

1. **Deep nesting**: Limited to 100 levels, so worst case is O(100 × (M + N)) ≈ O(M + N)
2. **Many wildcards**: `$..` matching entire document requires O(K) path evaluation where K = document size
3. **Large objects**: Flat objects with many keys still O(M + N) due to hash-based lookups

## Conclusion

JSON.MERGE achieves **O(M + N)** time complexity for single-path merges and **O(M_total + P × N)** for multi-path merges, where the algorithm scales linearly with the size of the data being merged.

