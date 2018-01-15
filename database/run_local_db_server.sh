docker run --name local_postgres -p 5432:5432  --mount source=local_postgres,target=/var/lib/postgresql/data -e POSTGRES_PASSWORD=Password123 -d postgres
