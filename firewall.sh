#!/bin/bash

# Цвета для вывода, для запуска использовать ./firewall.sh
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # Нет цвета

# Функция проверки установлен ли ufw
check_ufw() {
    if ! command -v ufw &> /dev/null; then
        echo -e "${RED}UFW не установлен! Устанавливаю...${NC}"
        sudo apt update && sudo apt install -y ufw
    fi
}

# Функция включения UFW
enable_ufw() {
    sudo ufw enable
    echo -e "${GREEN}Брандмауэр включен!${NC}"
}

# Функция отключения UFW
disable_ufw() {
    sudo ufw disable
    echo -e "${RED}Брандмауэр отключен!${NC}"
}

# Функция сброса правил UFW
reset_ufw() {
    sudo ufw reset
    echo -e "${RED}Брандмауэр сброшен!${NC}"
}

# Функция добавления правила
add_rule() {
    echo "Введите порт (или сервис, например, ssh, http, https):"
    read port
    sudo ufw allow "$port"
    echo -e "${GREEN}Разрешен доступ к $port${NC}"
}

# Функция удаления правила
delete_rule() {
    echo "Введите порт (или сервис), который нужно удалить:"
    read port
    sudo ufw delete allow "$port"
    echo -e "${RED}Удалено правило для $port${NC}"
}

# Функция отображения статуса UFW
show_status() {
    sudo ufw status verbose
}

# Главное меню
while true; do
    clear
    echo -e "${GREEN}Меню управления UFW:${NC}"
    echo "1) Включить UFW"
    echo "2) Отключить UFW"
    echo "3) Сбросить настройки"
    echo "4) Добавить правило"
    echo "5) Удалить правило"
    echo "6) Показать статус"
    echo "7) Выйти"
    echo "Выберите действие: "
    read -r option

    case $option in
        1) check_ufw; enable_ufw ;;
        2) disable_ufw ;;
        3) reset_ufw ;;
        4) add_rule ;;
        5) delete_rule ;;
        6) show_status ;;
        7) exit 0 ;;
        *) echo -e "${RED}Неверный ввод!${NC}" ;;
    esac

    echo "Нажмите Enter для продолжения..."
    read
done