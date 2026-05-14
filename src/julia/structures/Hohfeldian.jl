# Hohfeldian Position System
# Represents the 8 fundamental legal positions in Hohfeld's framework

# Position as three booleans — your binary matrix
struct Position
    perspective::Bool  # true = Holder, false = Counterparty
    polarity::Bool     # true = Positive, false = Negative
    order::Bool        # true = First, false = Second
end

# The 8 positions as constants
# (Holder, Positive, First) = (true, true, true)
const Right      = Position(true,  true,  true)   # Holder, Positive, First
const Duty       = Position(false, true,  true)   # Counterparty, Positive, First
const NoRight    = Position(true,  false, true)   # Holder, Negative, First
const Privilege  = Position(false, false, true)   # Counterparty, Negative, First
const Power      = Position(true,  true,  false)  # Holder, Positive, Second
const Liability  = Position(false, true,  false)  # Counterparty, Positive, Second
const Disability = Position(true,  false, false)  # Holder, Negative, Second
const Immunity   = Position(false, false, false)  # Counterparty, Negative, Second

# Operators on position
O(p::Position) = Position(p.perspective, !p.polarity, p.order)
C(p::Position) = Position(!p.perspective, p.polarity, p.order)
E(p::Position) = Position(p.perspective, p.polarity, !p.order)

# Positional helper functions
is_holder_view(p::Position) = p.perspective
is_positive(p::Position) = p.polarity
is_first_order(p::Position) = p.order

# Complementary helpers for readability
is_counterparty_view(p::Position) = !p.perspective
is_negative(p::Position) = !p.polarity
is_second_order(p::Position) = !p.order

# Position relationship functions
are_opposites(pos1::Position, pos2::Position) = pos1 == O(pos2)
are_correlatives(pos1::Position, pos2::Position) = pos1 == C(pos2)
are_order_transforms(pos1::Position, pos2::Position) = pos1 == E(pos2)

# Position to name mapping for encoding/display
const POSITION_NAMES = Dict{Position, String}(
    Right      => "Right",
    Duty       => "Duty",
    NoRight    => "NoRight",
    Privilege  => "Privilege",
    Power      => "Power",
    Liability  => "Liability",
    Disability => "Disability",
    Immunity   => "Immunity"
)

# Helper function to get position name
position_name(p::Position) = get(POSITION_NAMES, p, "Unknown")

# Reverse mapping: name to position (for parsing/debugging)
const NAME_TO_POSITION = Dict{String, Position}(
    "Right"      => Right,
    "Duty"       => Duty,
    "NoRight"    => NoRight,
    "Privilege"  => Privilege,
    "Power"      => Power,
    "Liability"  => Liability,
    "Disability" => Disability,
    "Immunity"   => Immunity
)

# Position classification sets
const PROCEDURABLE_POSITIONS = Set([Right, Duty, Power])
const NEGATIVE_POSITIONS = Set([NoRight, Privilege, Disability, Immunity])
const FIRST_ORDER_POSITIONS = Set([Right, Duty, NoRight, Privilege])
const SECOND_ORDER_POSITIONS = Set([Power, Liability, Disability, Immunity])

# Hohfeldian keyword to Position mapping
const HOHFELD_KEYWORDS = Dict{String, Position}(
    # English keywords
    "must" => Duty,
    "has privilege to" => Privilege,
    "may" => Privilege,
    "has right to" => Right,
    "has no right to" => NoRight,
    "has power to" => Power,
    "can" => Power,
    "has no power to" => Disability,
    "cannot" => Disability,
    "is subject to" => Liability,
    "has immunity from" => Immunity,
    "is protected from" => Immunity,
    # French keywords (from translation table)
    "doit" => Duty,
    "peut" => Privilege,
    "a le droit de" => Right,
    "n'a pas le droit de" => NoRight,
    "a le pouvoir de" => Power,
    "ne peut pas" => Disability,
    "est soumis à" => Liability,
    "est protégé de" => Immunity
)

# Get Position from Hohfeldian keyword
function get_position(keyword::Union{String, SubString{String}})
    key = lowercase(strip(String(keyword)))
    get(HOHFELD_KEYWORDS, key, nothing)
end