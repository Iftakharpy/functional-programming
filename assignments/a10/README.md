## Run database using `docker`
```bash
docker run --name postgres_alpine -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=postgres -p 5432:5432 -d postgres:alpine
```
