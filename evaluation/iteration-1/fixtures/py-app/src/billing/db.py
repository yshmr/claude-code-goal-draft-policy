class DB:
    def query_raw(self, sql: str):
        """DEPRECATED: use query() instead."""
        return self._execute(sql)

    def query(self, sql: str, params: dict | None = None):
        return self._execute(sql, params or {})

    def _execute(self, sql, params=None):
        return []
