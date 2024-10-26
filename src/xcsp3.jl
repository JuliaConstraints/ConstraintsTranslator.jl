const XCSP_USAGE = Dict(
    :all_different => """
        # Global constraint ensuring all values in X are different from each other.
        # Commonly used in problems requiring unique assignments (e.g., scheduling, assignment problems).
        @constraint(model, X1 in AllDifferent())

        # The :vals keyword allows specifying values that can be repeated
        # These values are excluded from the uniqueness check
        @constraint(model, X2 in AllDifferent(; vals = [0]))  # Allows multiple zeros
        @constraint(model, X3 in AllDifferent(; vals = [0, -1]))  # Allows multiple zeros and -1s

        # Examples of valid assignments:
        # [1, 2, 3, 4]           # All values different
        # [1, 0, 0, 4]           # Valid with vals=[0]
        # [1, 2, 3, 1]           # Invalid (1 is repeated)
    """,
    :all_equal => """
        # Global constraint ensuring all values in X are equal, with optional transformations.
        # Useful in synchronization and uniformity constraints.
        @constraint(model, X1 in AllEqual())  # All values must be identical

        # Parameters for transformed equality checks:
        # - op: Operation to apply before equality check (default: +)
        # - val: Target value for comparison (default: first value)
        # - pair_vars: Coefficients for each variable (default: zeros)
        @constraint(model, X2 in AllEqual(; pair_vars = [0, 1, 2, 3]))  # Linear transformation
        @constraint(model, X3 in AllEqual(; op = /, val = 1, pair_vars = [1, 2, 3, 4]))  # Division
        @constraint(model, X4 in AllEqual(; op = *, val = 1, pair_vars = [1, 2, 3, 4]))  # Multiplication

        # Examples of valid assignments:
        # [0, 0, 0, 0]           # Direct equality
        # [3, 2, 1, 0] with pair_vars=[0, 1, 2, 3]  # Equal after transformation
        # [1, 2, 3, 4] with op=/, val=1, pair_vars=[1, 2, 3, 4]  # Equal after division
    """,
    :cardinality => """
        # Global constraint controlling how many times specific values can appear.
        # Essential for resource allocation and counting constraints.

        # Basic usage: vals matrix specifies [value min max] for each row
        # Each value must occur between min and max times
        @constraint(model, X1 in Cardinality(; vals = [2 0 1;   # 2 can appear 0-1 times
                                                    5 1 3;   # 5 can appear 1-3 times
                                                    10 2 3])) # 10 can appear 2-3 times

        # The :bool parameter controls whether values outside vals are allowed
        # false (default): Other values allowed (CardinalityOpen)
        # true: Only listed values allowed (CardinalityClosed)
        @constraint(model, X2 in Cardinality(; vals = [2 0 1; 5 1 3; 10 2 3], bool = true))

        # Convenience variants:
        @constraint(model, X3 in CardinalityOpen(; vals = [2 0 1; 5 1 3; 10 2 3]))   # Allows other values
        @constraint(model, X4 in CardinalityClosed(; vals = [2 0 1; 5 1 3; 10 2 3])) # Restricts to listed values

        # Examples of valid assignments:
        # [2, 5, 10, 10]         # Valid: meets all cardinality requirements
        # [8, 5, 10, 10]         # Valid for Open, invalid for Closed (8 not in vals)
        # [5, 5, 5, 10]          # Invalid: too many 5s
    """,
    :channel => """
        # Constraint ensuring bidirectional mapping between values and indices
        # For each X[i]=j must have X[j]=i (inverse relationship)

        # Basic channel for inverse mapping
        @constraint(model, X in Channel())  # [2,1,4,3] ✓ since X[1]=2, X[2]=1

        # Dimensional variants:
        @constraint(model, Y in Channel(; dim=2))  # Splits array in half for mapping
        # [2,1,5,3,4, 2,1,4,5,3] ✓ First half maps to second half

        # Single value check mode
        @constraint(model, Z in Channel(; id=3))  # Only one true value at position 3
        # [false,false,true,false] ✓

        Examples of valid configurations:
        - dim=1: [2,1,4,3]    # Each value points to its inverse
        - dim=2: [1,2, 2,1]   # First half maps to second half
        - id=2: [0,1,0,0]     # Single 1 at position 2

        Parameters:
        - dim: Check dimension (1 or 2)
        - id: Position for single value check
    """,
    :circuit => """
        # Global constraint ensuring values form a circuit where each value points to next index.
        # The sequence must eventually loop back to the start. Used in routing problems.
        @constraint(model, X1 in Circuit())

        # The :op keyword specifies comparison operation for circuit length validation
        # Default operation is ≥ (greater than or equal)
        @constraint(model, X2 in Circuit(; op = >=))  # [2,3,4,1] is valid
        @constraint(model, X3 in Circuit(; op = ==))  # Exact length match

        # The :val keyword specifies the target value for circuit length comparison
        # Default value is length(x)
        @constraint(model, X4 in Circuit(; val = 3))  # Circuit must be length 3
        @constraint(model, X5 in Circuit(; op = ==, val = 3))  # [2,3,1,4] is valid

        # Examples of valid circuits:
        # [2,3,4,1] forms complete circuit: 1->2->3->4->1
        # [2,3,1,4] with op=== and val=3 forms circuit of length 3: 1->2->3->1
        # [4,3,1,3] with op=> and val=0 forms valid circuit with some repeated values
    """,
    :count => """
        # Family of constraints controlling how many times specified values can appear.
        # Useful for resource allocation, load balancing, and quota enforcement.

        # Base Count constraint with flexible comparison:
        # - vals: Values to count occurrences of
        # - op: Comparison operator (≥, ≤, ==)
        # - val: Target count to compare against
        @constraint(model, X1 in Count(vals=[1, 2, 3, 4], op=≥, val=2))  # At least 2 values from 1-4
        @constraint(model, X2 in Count(vals=[1, 2], op=≤, val=3))        # At most 3 values from 1-2
        @constraint(model, X3 in Count(vals=[5], op==, val=2))           # Exactly 2 fives

        # Specialized variants for common cases:
        # AtLeast: Count must be greater than or equal to val
        @constraint(model, X4 in AtLeast(vals=[1, 2, 3, 4], val=2))  # Same as Count with op=≥

        # AtMost: Count must be less than or equal to val
        @constraint(model, X5 in AtMost(vals=[1, 2], val=1))         # Same as Count with op=≤

        # Exactly: Count must equal val exactly
        @constraint(model, X6 in Exactly(vals=[1, 2], val=2))        # Same as Count with op==

        # Examples of valid assignments:
        # [2, 1, 4, 3] with vals=[1, 2, 3, 4], op=≥, val=2    # Valid: contains 4 matching values
        # [1, 2, 3, 4] with vals=[1, 2], op==, val=2          # Valid: contains exactly 2 values from [1,2]
        # [3, 4, 5, 5] with vals=[5], op==, val=2             # Valid: contains exactly 2 fives
        # [2, 1, 4, 3] with vals=[1, 2], op=≤, val=1          # Invalid: contains 2 values, exceeds max of 1

        Note: These constraints are more flexible than Cardinality when you need to:
        1. Count multiple values as a single group
        2. Use different comparison operators
        3. Focus on specific subsets of values
    """,
    :at_least => """
       # Constraint ensuring a minimum number of occurrences for specified values.
       # Simplified version of Count with ≥ operator.
       @constraint(model, X1 in AtLeast(vals=[1, 2, 3, 4], val=2))  # At least 2 values from 1-4

       # Common use cases:
       # - Minimum resource requirements
       # - Lower bounds on assignments
       # - Quota enforcement
       @constraint(model, X2 in AtLeast(vals=[1], val=3))     # At least 3 ones
       @constraint(model, X3 in AtLeast(vals=[2, 3], val=4))  # At least 4 values from [2,3]
    """,
    :at_most => """
        # Constraint ensuring a maximum number of occurrences for specified values.
        # Simplified version of Count with ≤ operator.
        @constraint(model, X1 in AtMost(vals=[1, 2], val=1))  # At most 1 value from [1,2]

        # Common use cases:
        # - Capacity constraints
        # - Upper bounds on assignments
        # - Resource limitations
        @constraint(model, X2 in AtMost(vals=[1], val=2))     # At most 2 ones
        @constraint(model, X3 in AtMost(vals=[2, 3], val=3))  # At most 3 values from [2,3]
    """,
    :exactly => """
        # Constraint ensuring an exact number of occurrences for specified values.
        # Simplified version of Count with == operator.
        @constraint(model, X1 in Exactly(vals=[1, 2], val=2))  # Exactly 2 values from [1,2]

        # Common use cases:
        # - Fixed resource allocations
        # - Exact matching requirements
        # - Precise counting constraints
        @constraint(model, X2 in Exactly(vals=[1], val=3))     # Exactly 3 ones
        @constraint(model, X3 in Exactly(vals=[2, 3], val=4))  # Exactly 4 values from [2,3]
    """,
    :cumulative => """
        # Scheduling constraint ensuring resource usage limits over time.
        # Tasks defined by start times (X values), durations and heights (pair_vars).

        # Basic case: Non-overlapping tasks
        @constraint(model, X in Cumulative(; val=1))  # Tasks cannot overlap
        # Valid: [1, 2, 3, 4, 5]   # Sequential scheduling
        # Invalid: [1, 2, 2, 4, 5] # Overlap at time 2

        # Resource-constrained scheduling
        @constraint(model, Y in Cumulative(;
        pair_vars = [3 2 5 4 2;  # Durations
                    1 2 1 1 3],  # Resource usage
        op = ≤,  # Operator for limit
        val = 5  # Max resource usage
        ))

        # Common uses:
        # - Machine scheduling with capacity limits
        # - Project resource management
        # - Production line balancing

        Note: At any time point, sum of resource usage (heights)
        of active tasks must satisfy: sum(heights) op val
    """,
    :element => """
        # Constraint linking index to specific value in array
        # Core: X[index] = value

        # Basic usage with explicit index and value
        @constraint(model, X in Element(;
            id = 2,    # Index to check
            val = 5    # Required value at that index
        ))  # Ensures X[2] = 5

        # Implicit indexing: X[X[1]] = X[end]
        @constraint(model, Y in Element())

        Examples:
        - id=2, val=5: [1,5,3,4]     ✓ X[2]=5
        - Implicit: [2,5,3,5]        ✓ X[X[1]]=X[4]
        - Implicit: [3,5,4,3]        ✗ X[X[1]]≠X[4]

        Parameters:
        - id: Index to check (default: first element)
        - val: Required value (default: last element)
        - op: Comparison (default: ==)
    """,
    :extension => """
        # Family of constraints defining allowed/forbidden value combinations

        # Extension with list of valid tuples
        @constraint(model, X in Extension(;
        pair_vars = [[1,2,3,4,5]]  # Only this tuple is valid
        ))
        # Extension with list of forbidden tuples
        @constraint(model, Y in Extension(;
        pair_vars = [[1,2,1,4,5], [1,2,3,5,5]]  # These tuples are forbidden
        ))

        # Supports: Must match one of these tuples exactly
        @constraint(model, X_Supports in Supports(;
        pair_vars = [[1,2,3,4,5]]
        ))

        # Conflicts: Must not match any of these tuples
        @constraint(model, X_Conflicts in Conflicts(;
        pair_vars = [[1,2,1,4,5], [1,2,3,5,5]]
        ))

        Note: Extension takes either supported tuples or conflict tuples.
        Supports/Conflicts are specialized versions for clearer intent.
    """,
    :instantiation => """
        # Constraint requiring exact match with specified sequence
        # Variables must take values in the exact order given

        # Enforce specific sequence of values
        @constraint(model, X in Instantiation(;
        pair_vars = [1, 2, 3, 4, 5]  # Must match exactly this sequence
        ))

        Examples:
        - [1,2,3,4,5] ✓ Matches sequence exactly
        - [1,2,3,4,6] ✗ Last value differs
        - [1,2,3,5,4] ✗ Same values, wrong order

        Note: Unlike Extension, order matters and all positions must match exactly.
    """,
    :maximum => """
        # Constraint on maximum value in array with comparison
        # Ensures max(X) op val is satisfied

        # Basic maximum equality check
        @constraint(model, X in Maximum(;
        op = ==,  # Comparison operator
        val = 5   # Target value
        ))

        Examples:
        - [1,2,3,4,5] with op=== val=5  ✓ max is 5
        - [1,2,3,4,5] with op=== val=6  ✗ max is 5, not 6
        - [1,2,3,4,5] with op=≤  val=6  ✓ max is ≤ 6

        Parameters:
        - op: Comparison (==, ≤, ≥, etc.)
        - val: Value to compare against
    """,
    :mdd => """
        # Multi-valued Decision Diagram (MDD) constraint
        # Models paths through directed graph where nodes/edges have values

        # Define MDD structure with state transitions
        states = [
        Dict(  # Level 1
            (:r, 0) => :n1,  # From root with value 0
            (:r, 1) => :n2,  # From root with value 1
            (:r, 2) => :n3   # From root with value 2
        ),
        Dict(  # Level 2
            (:n1, 2) => :n4, # From n1 with value 2
            (:n2, 2) => :n4, # From n2 with value 2
            (:n3, 0) => :n5  # From n3 with value 0
        ),
        Dict(  # Level 3
            (:n4, 0) => :t,  # To terminal with value 0
            (:n5, 0) => :t   # To terminal with value 0
        )
        ]

        # Apply MDD constraint
        @constraint(model, X in MDDConstraint(;
        language = MDD(states)
        ))

        Valid paths through this MDD:
        [0,2,0], [1,2,0], [2,0,0]  # Reach terminal node
        Invalid paths:
        [2,1,2], [1,0,2], [0,1,2]  # Don't reach terminal
    """,
    :minimum => """
        # Constraint on minimum value in array with comparison
        # Ensures min(X) op val is satisfied

        # Basic minimum equality check
        @constraint(model, X in Minimum(;
        op = ==,  # Comparison operator
        val = 3   # Target value
        ))

        Examples:
        - [3,4,5] with op=== val=3  ✓ min is 3
        - [1,2,3] with op=== val=3  ✗ min is 1
        - [4,5,6] with op=≥  val=3  ✓ min is ≥ 3

        Parameters:
        - op: Comparison (==, ≤, ≥, etc.)
        - val: Value to compare against
    """,
    :nvalues => """
        # Constraint on number of distinct values in array
        # Ensures count(unique(X)) op val is satisfied

        # Check for exact number of distinct values
        @constraint(model, X in NValues(;
        op = ==,  # Comparison operator
        val = 5   # Target distinct count
        ))

        # Limit maximum distinct values
        @constraint(model, Y in NValues(;
        op = <=,  # Less than or equal
        val = 5,  # Maximum distinct values
        vals = [1,2]  # Optional: exclude these from count
        ))

        Examples:
        - [1,2,3,4,5] with op=== val=5  ✓ 5 distinct values
        - [1,2,2,3,3] with op=== val=3  ✓ 3 distinct values
        - [1,2,3,4,4] with op=≤  val=3  ✗ 4 distinct values
        - [1,2,3,4] with vals=[1,2] op=≤ val=2  ✓ 2 distinct after excluding [1,2]

        Parameters:
        - op: Comparison operator
        - val: Target count
        - vals: Optional values to exclude
    """,
    :no_overlap => """
        # Scheduling constraint ensuring tasks don't overlap in time
        # Each task has start time (X values) and duration (pair_vars)

        # Basic non-overlapping tasks (unit duration)
        @constraint(model, X in NoOverlap())  # Default duration=1

        # Tasks with specified durations
        @constraint(model, Y in NoOverlap(;
        pair_vars = [1,1,1,1,1]  # Duration for each task
        ))

        # Multi-dimensional scheduling (e.g., 3D space)
        @constraint(model, Z in NoOverlap(;
        pair_vars = [2,4,1,4,2,3,5,1,2,3,3,2],  # Durations
        dim = 3  # Check overlap in 3 dimensions
        ))

        Examples:
        - 1D: [1,3,5] with [1,1,1]  ✓ No overlap
        - 1D: [1,2,5] with [2,2,1]  ✗ Tasks 1&2 overlap
        - 3D: [x1,y1,z1,x2,y2,z2] checks overlap in 3D space

        Parameters:
        - pair_vars: Task durations (default: all 1)
        - dim: Number of dimensions (default: 1)
        - bool: Include zero-length tasks (default: true)
    """,
    :ordered => """
        # Family of constraints for value ordering
        # Ensures values follow specified ordering rules

        # Basic ordered (non-strict)
        @constraint(model, X in Ordered())  # Default: ≤

        # Strict ordering
        @constraint(model, Y in Ordered(; op = <))  # Strictly increasing

        # Specialized variants:
        @constraint(model, A in Increasing())        # Same as op = ≤
        @constraint(model, B in Decreasing())        # Same as op = ≥
        @constraint(model, C in StrictlyIncreasing())  # Same as op =
        @constraint(model, D in StrictlyDecreasing())  # Same as op = >

        Examples:
        - [1,2,3,4,4] with op=≤  ✓ Non-strict increasing
        - [1,2,3,4,5] with op=<  ✓ Strict increasing
        - [1,2,3,3,2] with op=≤  ✗ Not ordered
        - [5,4,3,2,1] with op=≥  ✓ Decreasing

        Parameters:
        - op: Comparison operator (≤, ≥, <, >)
        - pair_vars: Optional length values
    """,
    :regular => """
        # Ensures sequence follows automaton-defined pattern
        # Uses state transitions to validate values

        # Define automaton transitions
        states = Dict(
            (:a, 0) => :a,  # State a: 0 loops
            (:a, 1) => :b,  # a to b: requires 1
            (:b, 1) => :c,  # b to c: requires 1
            (:c, 0) => :d,  # c to d: requires 0
            (:d, 0) => :d   # State d: 0 loops
        )

        # Apply regular pattern constraint
        @constraint(model, X in Regular(;
            language = Automaton(states, :a, :d)  # start=a, accept=d
        ))

        Examples:
        - [0,0,1,1,0] ✓ Valid path: a->a->b->c->d
        - [1,0,1,1]   ✗ No path to accept state
        - [0,1,1,0,0] ✓ Reaches accept state d

        Note: Values must trace valid path from start
        to accept state through defined transitions.
    """,
    :sum => """
        # Linear constraint: sum(X .* coeffs) op val
        # Core: Verify that array sum satisfies comparison

        # Basic sum constraint
        @constraint(model, X in Sum(;
            op = ==,   # Required comparison
            val = 15   # Target value
        ))  # Ensures sum(X) = 15

        # Weighted sum with coefficients
        @constraint(model, Y in Sum(;
            pair_vars = [2,3,1],  # Weights for each X[i]
            op = <=,             # Upper bound check
            val = 20             # Maximum weighted sum
        ))  # Ensures 2X₁ + 3X₂ + X₃ ≤ 20

        Examples:
        - sum=15: [5,5,5]       ✓ Sum is 15
        - sum≤10: [2,3,4]       ✗ Sum is 9
        - [2,3,1] with weights [2,1,3]: 4+3+3=10  ✓

        Parameters:
        - op: Comparison (==,≤,≥,etc)
        - val: Target value
        - pair_vars: Coefficients (default: ones)
    """,
)
