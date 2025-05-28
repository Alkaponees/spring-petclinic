#!/bin/bash

# Налаштування
VAULT_ADDR="http://127.0.0.1:8200"
VAULT_MOUNT="spring-petclinic"
VAULT_SECRET="SPRING_DOCKER"
VAULT_SECRET_POSTGRES="POSTGRESS"
OUTPUT_FILE_POSTGRES="docker/.env"
OUTPUT_FILE="docker/.app-env"

# Перевірка наявності vault CLI
if ! command -v vault &> /dev/null; then
    echo "Помилка: vault CLI не знайдений!"
    exit 1
fi

# Отримання даних з Vault
echo "Зчитування секрету з Vault для spring-petclinic-app..."
response=$(VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv get -mount="$VAULT_MOUNT" -format=json "$VAULT_SECRET")

# Перевірка на помилку
if [ $? -ne 0 ]; then
    echo "❌ Не вдалося зчитати секрет з Vault!"
    exit 1
fi

# Обробка JSON та вивід у файл
echo "# Автоматично згенерований файл з Vault" > "$OUTPUT_FILE"
echo "$response" | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' >> "$OUTPUT_FILE"

echo "✅ Секрети успішно збережені для spring-petclinic-app у $OUTPUT_FILE"

echo "Зчитування секрету з Vault для spring-petclinic-postgress..."
response=$(VAULT_ADDR=$VAULT_ADDR VAULT_TOKEN=$VAULT_TOKEN vault kv get -mount="$VAULT_MOUNT" -format=json "$VAULT_SECRET_POSTGRES")
# Перевірка на помилку
if [ $? -ne 0 ]; then
    echo "❌ Не вдалося зчитати секрет з Vault!"
    exit 1
fi
Обробка JSON та вивід у файл
echo "# Автоматично згенерований файл з Vault" > "$OUTPUT_FILE_POSTGRES"
echo "$response" | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' >> "$OUTPUT_FILE_POSTGRES"

echo "✅ Секрети успішно збережені для spring-petclinic-app у $OUTPUT_FILE_POSTGRES"
