from src.billing.invoices import overdue_invoices, paid_invoices


def test_overdue_returns_list():
    assert isinstance(overdue_invoices(), list)


def test_paid_returns_list():
    assert isinstance(paid_invoices(), list)
