#!/bin/bash

# Цвета для вывода
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # Сброс цвета

# Проверка root-прав
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Этот скрипт должен выполняться с root-правами!${NC}"
    exit 1
fi

# Функция установки скрипта в /usr/local/bin/mfw
install_script() {
    local SCRIPT_PATH="/usr/local/bin/mfw"
    if [[ "$(realpath "$0")" != "$SCRIPT_PATH" ]]; then
        echo -e "${GREEN}Устанавливаю скрипт как команду 'mfw'...${NC}"
        cp "$0" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo -e "${GREEN}Теперь можно запускать скрипт командой: mfw${NC}"
        exit 0
    fi
}

# Функция проверки и установки UFW
check_ufw() {
    if ! command -v ufw &> /dev/null; then
        echo -e "${RED}UFW не установлен! Устанавливаю...${NC}"
        apt update && apt install -y ufw
    fi
}

# Функция проверки и установки Fail2Ban
install_fail2ban() {
    if ! command -v fail2ban-client &> /dev/null; then
        echo -e "${RED}Fail2Ban не установлен! Устанавливаю...${NC}"
        apt update && apt install -y fail2ban
        systemctl enable --now fail2ban  # Включение Fail2Ban в автозапуск
        echo -e "${GREEN}Fail2Ban установлен, запущен и добавлен в автозапуск!${NC}"
    fi
}

# Функция удаления Fail2Ban
remove_fail2ban() {
    if command -v fail2ban-client &> /dev/null; then
        systemctl stop fail2ban
        apt remove --purge -y fail2ban
        echo -e "${GREEN}Fail2Ban успешно удален!${NC}"
    else
        echo -e "${RED}Fail2Ban не установлен!${NC}"
    fi
}

# Функция показа отчёта Fail2Ban
show_fail2ban_report() {
    if ! command -v fail2ban-client &> /dev/null; then
        echo -e "${RED}Fail2Ban не установлен!${NC}"
        return
    fi
    
    echo -e "${GREEN}Статус Fail2Ban:${NC}"
    systemctl status fail2ban --no-pager
    
    echo -e "\n${GREEN}Список заблокированных IP:${NC}"
    fail2ban-client status sshd | grep 'Banned IP list' || echo "Нет заблокированных IP"
}

# Функция включения UFW
enable_ufw() {
    ufw default deny incoming  # Блокировать все входящие соединения
    ufw default allow outgoing # Разрешить все исходящие соединения
    
    # Разрешить SSH, HTTP и HTTPS
    ufw allow 22/tcp  # SSH
    ufw allow 80/tcp  # HTTP
    ufw allow 443/tcp # HTTPS
    
    ufw enable # Включить UFW
    echo -e "${GREEN}Брандмауэр включен! Разрешены порты: 22 (SSH), 80 (HTTP), 443 (HTTPS).${NC}"
}

# Функция отключения UFW
disable_ufw() {
    ufw disable
    echo -e "${RED}Брандмауэр отключен!${NC}"
}

# Функция сброса правил UFW
reset_ufw() {
    ufw reset
    echo -e "${RED}Брандмауэр сброшен!${NC}"
}

# Функция добавления правила
add_rule() {
    echo "Введите порт (или сервис, например, ssh, http, https):"
    read port
    ufw allow "$port"
    echo -e "${GREEN}Разрешен доступ к $port${NC}"
}

# Функция удаления правила
delete_rule() {
    echo "Введите порт (или сервис), который нужно удалить:"
    read port
    ufw delete allow "$port"
    echo -e "${RED}Удалено правило для $port${NC}"
}

# Функция блокировки порта
block_rule() {
    echo "Введите порт (или сервис), который нужно заблокировать:"
    read port
    ufw deny "$port"
    echo -e "${RED}Заблокирован доступ к $port${NC}"
}

# Функция отображения статуса UFW
show_status() {
    ufw status verbose
}

# Функция удаления скрипта
remove_script() {
    local SCRIPT_PATH="/usr/local/bin/mfw"
    if [[ -f "$SCRIPT_PATH" ]]; then
        rm "$SCRIPT_PATH"
        echo -e "${GREEN}Скрипт успешно удален!${NC}"
    else
        echo -e "${RED}Скрипт не найден!${NC}"
    fi
}

# Проверка и установка UFW при запуске
check_ufw

# Установка скрипта как команды mfw
install_script

# Главное меню
while true; do
    clear
    echo -e "${GREEN}Меню управления UFW и Fail2Ban:${NC}"
    echo "1) Включить UFW (22, 80, 443)"
    echo "2) Отключить UFW"
    echo "3) Сбросить настройки UFW"
    echo "4) Добавить правило"
    echo "5) Удалить правило"
    echo "6) Заблокировать порт"
    echo "7) Показать статус UFW"
    echo "8) Fail2Ban"
    echo "9) Удалить скрипт, отключить фаервол и удалить Fail2Ban"
    echo "0) Выйти"
    echo "Выберите действие: "
    read -r option

    case $option in
        1) enable_ufw ;;
        2) disable_ufw ;;
        3) reset_ufw ;;
        4) add_rule ;;
        5) delete_rule ;;
        6) block_rule ;;
        7) show_status ;;
        8)
            while true; do
                clear
                echo -e "${GREEN}Меню Fail2Ban:${NC}"
                echo "1) Установить Fail2Ban"
                echo "2) Показать статус заблокированных IP для SSH"
                echo "3) Показать отчёт Fail2Ban"
                echo "0) Назад"
                echo "Выберите действие: "
                read -r fail2ban_option

                case $fail2ban_option in
                    1) install_fail2ban ;;
                    2) sudo fail2ban-client status sshd ;;
                    3) show_fail2ban_report ;;
                    0) break ;;
                    *) echo -e "${RED}Неверный ввод!${NC}" ;;
                esac

                echo "Нажмите Enter для продолжения..."
                read
            done
            ;;
        9)
            remove_script
            disable_ufw
            remove_fail2ban
            exit 0
            ;;
        0) break ;;  # Завершает цикл и выходит из скрипта
        *) echo -e "${RED}Неверный ввод!${NC}" ;;
    esac

    echo "Нажмите Enter для продолжения..."
    read
done