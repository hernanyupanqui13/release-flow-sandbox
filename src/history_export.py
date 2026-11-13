import csv
import io


def export_csv(transactions):
    """Return the given transactions as CSV text with a header row."""
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=["date", "description", "amount"])
    writer.writeheader()
    for transaction in transactions:
        writer.writerow({key: transaction[key] for key in writer.fieldnames})
    return buffer.getvalue()
