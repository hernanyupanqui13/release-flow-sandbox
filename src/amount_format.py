from decimal import ROUND_HALF_UP, Decimal


def format_amount(amount):
    """Format an amount in soles, rounded to two decimals with thousands separators."""
    rounded = Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return f"S/ {rounded:,}"
