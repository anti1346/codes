# Vault

##### Vault 서버 실행
```
vault server -dev
```
```
vault server -dev > /dev/null 2>&1 &
```
##### VAULT_ADDR 환경 변수 설정
```
export VAULT_ADDR='http://127.0.0.1:8200'
```
#### Vault 서버 초기화 및 언실
##### Vault 서버 초기화
```
vault operator init
```
```
$ vault operator init
Unseal Key 1: 5_____S
Unseal Key 2: 8_____m
Unseal Key 3: T_____W
Unseal Key 4: t_____v
Unseal Key 5: g_____3

Initial Root Token: hvs.s_____r
```
##### VAULT_TOKEN 환경 변수 설정
```
export VAULT_TOKEN="hvs.s_____r"
``` 
##### Vault 서버 언실
```
vault operator unseal 5_____S
```
```
vault operator unseal 8_____m
```
```
vault operator unseal T_____W
```
##### Vault 로그인
```
vault login hvs.s_____r
```

