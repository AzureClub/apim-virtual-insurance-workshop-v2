import os
import json
import logging
from typing import List, Dict

import azure.functions as func

import psycopg2
from psycopg2 import sql

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)


def _get_db_conn():
    """Create and return a new psycopg2 connection using env vars."""
    return psycopg2.connect(
        host=os.getenv("PG_HOST"),
        port=int(os.getenv("PG_PORT", "5432")),
        dbname=os.getenv("PG_DATABASE"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
    )


def vector_search(
    query: str,
    table: str = "policies",
    id_column: str = "polisa_id",
    content_column: str = "opis",
) -> List[Dict]:
    """Perform a vector similarity search against an Azure PostgreSQL DB with `pgvector`.

    - `query`: text to search for. 
    - Returns a list of dicts with `id`, `content`.
    """
    conn = _get_db_conn()
    try:
        with conn.cursor() as cur:
            q = sql.SQL(
                "SELECT {id_col}, {content_col} "
                "FROM {table} "
                "ORDER BY embedding <#> azure_openai.create_embeddings('text-embedding-ada-002', {query})::vector "
                "LIMIT 1"
            ).format(
                id_col=sql.Identifier(id_column),
                content_col=sql.Identifier(content_column),
                query=sql.Literal(query),
                table=sql.Identifier(table),
            )

            cur.execute(q)
            rows = cur.fetchall()

            results = []
            for r in rows:
                results.append({"id": r[0], "content": r[1]})

            return results
    finally:
        conn.close()

@app.route(route="get_policies", methods=("GET","POST"))
def get_policies(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        params = req.get_json()
    except Exception:
        params = {}

    query = req.params.get("q") or req.params.get("query") or params.get("q") or params.get("query")
    if not query:
        return func.HttpResponse("Missing 'query' parameter", status_code=400)
    
    try:
        results = vector_search(query)
    except Exception as e:
        logging.exception("vector_search failed")
        return func.HttpResponse(str(e), status_code=500)

    return func.HttpResponse(json.dumps(results), mimetype="application/json", status_code=200)