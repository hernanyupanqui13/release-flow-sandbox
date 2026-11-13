from decimal import ROUND_HALF_UP, Decimal


def format_amount(amount):
    """Format an amount in soles, always rounded to two decimals."""
    rounded = Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return f"S/ {rounded}"
