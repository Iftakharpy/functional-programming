## Run database using `docker`
```bash
docker run --name pga -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=books_api_dev -p 5432:5432 -d postgres:alpine
```
