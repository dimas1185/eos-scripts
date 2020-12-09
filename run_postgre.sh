docker stop df_postgre
docker rm df_postgre
docker run --name df_postgre  -p 5432:5432 -e POSTGRES_PASSWORD=test -d postgres