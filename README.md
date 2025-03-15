# 🔥 Firewall  

Скрипт для настройки фаервола на Linux. Позволяет быстро защитить сервер от несанкционированного доступа.  

⚠ **Важно:** Перед включением убедитесь, что порт `22` (SSH) открыт, иначе можно потерять доступ к серверу, после установки и запуска скрипта, создайте правило для порта 22, **только потом** включайте фаервол!  

## 📥 Установка и запуск  

1. **Скачать скрипт:**  
   ```sh
   wget https://raw.githubusercontent.com/00firefly00/Firewall/main/firewall.sh

2. **Дать права:**
   ```sh
   chmod +x firewall.sh

3. **Запустить:**
   ```sh
   ./firewall.sh
