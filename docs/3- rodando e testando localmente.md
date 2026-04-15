

rode com
```
php artisan serve
```

# exemplo de post de usuario

```sh
curl -X POST http://127.0.0.1:8000/api/users \
-H "Content-Type: application/json" \
-d '{
  "name": "Gabriel",
  "email": "gabriel@email.com",
  "password": "123456",
  "role": "admin"
}'

```


```sh
curl -X GET http://127.0.0.1:8000/api/users \
-H "Content-Type: application/json" \
```
