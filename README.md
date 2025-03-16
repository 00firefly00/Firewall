# 🔥 Firewall  

Простой скрипт для настройки фаервола на Linux Ubuntu. Позволяет быстро защитить сервер от несанкционированного доступа, включена возможность установки fail2ban 

⚠ **Важно:** Нажав кнопку включить UFW, скрипт автоматически закроет все входящие соединения, создаст правило для SSH (22), что бы не потерять соединение с сервером и дополнительно откроет HTTP (80), HTTPS (443).

## 📥 Установка и запуск  

1. **Скачать скрипт и установить:**  
   ```sh
   sudo bash -c 'wget https://raw.githubusercontent.com/00firefly00/Firewall/e6c5525afedf2a8bd8023d5d226842b7b088b66c/firewall.sh -O /usr/local/bin/firewall.sh && chmod +x /usr/local/bin/firewall.sh && /usr/local/bin/firewall.sh'


2. **Запустить:**
   ```sh
   mfw

## Меню управления

[![IMG-20250316-173106.jpg](https://i.postimg.cc/Gt9WqTzz/IMG-20250316-173106.jpg)](https://postimg.cc/WqLY43BJ)
