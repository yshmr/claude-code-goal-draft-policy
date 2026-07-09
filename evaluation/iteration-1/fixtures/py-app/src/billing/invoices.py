from .db import DB

db = DB()


def overdue_invoices():
    return db.query_raw("SELECT * FROM invoices WHERE due < now()")


def paid_invoices():
    return db.query_raw("SELECT * FROM invoices WHERE status = 'paid'")
