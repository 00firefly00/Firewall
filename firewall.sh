#!/bin/bash

# Цвета для вывода
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # Сброс цвета

# Пути
SCRIPT_PATH=$(realpath "$0")
INSTALL_PATH="/usr/local/bin/mfw"

# Функция установки скрипта как команды mfw
install_script() {
    cp "$SCRIPT_PATH" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    echo -e "${GREEN}Скрипт автоматически установлен! Теперь можно использовать команду 'mfw'.${NC}"
}

# Автоматическая установка, если запуск происходит через ./firewall.sh
if [[ "$SCRIPT_PATH" != "$INSTALL_PATH" && "$SCRIPT_PATH" == */firewall.sh ]]; then
    echo -e "${GREEN}Скрипт обнаружен как 'firewall.sh'. Автоматическая установка...${NC}"
    install_script
fi

# Проверка root-прав
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Этот скрипт должен выполняться с root-правами!${NC}"
    exit 1
fi

# Обработка SIGINT (Ctrl+C)
trap "echo -e '${RED}Скрипт прерван пользователем.${NC}'; exit 1" SIGINT

# Функция удаления скрипта
remove_script() {
    if [[ -f "$INSTALL_PATH" ]]; then
        rm "$INSTALL_PATH"
        echo -e "${GREEN}Команда 'mfw' удалена!${NC}"
    else
        echo -e "${RED}Команда 'mfw' не найдена!${NC}"
    fi

    disable_ufw
    remove_fail2ban
    exit 0
}

# Функция проверки и установки UFW
check_ufw() {
    if ! command -v ufw &> /dev/null; then
        echo -e "${RED}UFW не установлен! Устанавливаю...${NC}"
        apt update && apt install -y ufw
    fi
}

# Функция включения UFW
enable_ufw() {
    check_ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw enable
    echo -e "${GREEN}Брандмауэр включен! Разрешены порты: 22 (SSH), 80 (HTTP), 443 (HTTPS).${NC}"
}

# Функция отключения UFW
disable_ufw() {
    check_ufw
    ufw disable
    echo -e "${RED}Брандмауэр отключен!${NC}"
}

# Функция сброса правил UFW
reset_ufw() {
    check_ufw
    ufw reset
    echo -e "${RED}Брандмауэр сброшен!${NC}"
}

# Функция отображения статуса UFW
show_status() {
    check_ufw
    ufw status verbose
}

# Функция добавления правил (несколько портов)
add_rule() {
    echo "Введите порты через запятую (например: 22,80,443):"
    read -r ports
    IFS=',' read -ra ports_array <<< "$ports"

    for port in "${ports_array[@]}"; do
        port_clean=$(echo "$port" | xargs)
        ufw allow "$port_clean"
        echo -e "${GREEN}Разрешен доступ к порту: $port_clean${NC}"
    done
}

# Функция удаления правил (несколько портов)
delete_rule() {
    echo "Введите порты через запятую (например: 22,80,443):"
    read -r ports
    IFS=',' read -ra ports_array <<< "$ports"

    for port in "${ports_array[@]}"; do
        port_clean=$(echo "$port" | xargs)
        ufw delete allow "$port_clean"
        echo -e "${RED}Удалено правило для порта: $port_clean${NC}"
    done
}

# Функция блокировки портов (несколько портов)
block_rule() {
    echo "Введите порты через запятую (например: 22,80,443):"
    read -r ports
    IFS=',' read -ra ports_array <<< "$ports"

    for port in "${ports_array[@]}"; do
        port_clean=$(echo "$port" | xargs)
        ufw deny "$port_clean"
        echo -e "${RED}Заблокирован доступ к порту: $port_clean${NC}"
    done
}

# Функция установки Fail2Ban
install_fail2ban() {
    if ! command -v fail2ban-client &> /dev/null; then
        echo -e "${RED}Fail2Ban не установлен! Устанавливаю...${NC}"
        apt update && apt install -y fail2ban
        systemctl enable --now fail2ban
        echo -e "${GREEN}Fail2Ban установлен и запущен!${NC}"
    else
        echo -e "${GREEN}Fail2Ban уже установлен!${NC}"
    fi
}

# Функция удаления Fail2Ban
remove_fail2ban() {
    if command -v fail2ban-client &> /dev/null; then
        systemctl stop fail2ban
        systemctl disable fail2ban
        apt remove --purge -y fail2ban
        echo -e "${GREEN}Fail2Ban удален!${NC}"
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

# Меню управления UFW
ufw_menu() {
    while true; do
        tput clear
        echo -e "${GREEN}Меню управления UFW:${NC}"
        echo "1) Включить UFW"
        echo "2) Отключить UFW"
        echo "3) Сбросить настройки UFW"
        echo "4) Показать статус UFW"
        echo "5) Удалить скрипт и отключить защиту"
        echo "0) Назад"
        echo "Выберите действие: "
        read -r option

        case $option in
            1) enable_ufw ;;
            2) disable_ufw ;;
            3) reset_ufw ;;
            4) show_status ;;
            5) remove_script ;;
            0) break ;;
            *) echo -e "${RED}Неверный ввод!${NC}" ;;
        esac

        echo "Нажмите Enter для продолжения..."
        read -r
    done
}

# Меню управления Fail2Ban
fail2ban_menu() {
    while true; do
        tput clear
        echo -e "${GREEN}Меню управления Fail2Ban:${NC}"
        echo "1) Установить Fail2Ban"
        echo "2) Показать отчёт Fail2Ban"
        echo "3) Удалить Fail2Ban"
        echo "0) Назад"
        echo "Выберите действие: "
        read -r option

        case $option in
            1) install_fail2ban ;;
            2) show_fail2ban_report ;;
            3) remove_fail2ban ;;
            0) break ;;
            *) echo -e "${RED}Неверный ввод!${NC}" ;;
        esac

        echo "Нажмите Enter для продолжения..."
        read -r
    done
}

# Главное меню
while true; do
    tput clear
    echo -e "${GREEN}Меню управления UFW и Fail2Ban:${NC}"
    echo "1) Управление UFW"
    echo "2) Добавить правило"
    echo "3) Удалить правило"
    echo "4) Заблокировать порт"
    echo "5) Управление Fail2Ban"
    echo "0) Выйти"
    echo "Выберите действие: "
    read -r option

    case $option in
        1) ufw_menu ;;
        2) add_rule ;;
        3) delete_rule ;;
        4) block_rule ;;
        5) fail2ban_menu ;;
        0) break ;;
        *) echo -e "${RED}Неверный ввод!${NC}" ;;
    esac

    echo "Нажмите Enter для продолжения..."
    read -r
done