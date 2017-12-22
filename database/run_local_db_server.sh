docker run --name local_postgres -p 5432:5432 -v /tmp/pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=Password123 -d postgres
