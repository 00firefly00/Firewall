#!/bin/bash

# Цвета для вывода
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # Сброс цвета

# Обработка SIGINT (Ctrl+C)
trap "echo -e '${RED}Скрипт прерван пользователем.${NC}'; exit 1" SIGINT

# Проверка root-прав
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Этот скрипт должен выполняться с root-правами!${NC}"
    exit 1
fi

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
    ufw default deny incoming  # Блокировать все входящие соединения
    ufw default allow outgoing # Разрешить все исходящие соединения

    # Разрешить SSH, HTTP и HTTPS
    ufw allow 22/tcp  # SSH
    ufw allow 80/tcp  # HTTP
    ufw allow 443/tcp # HTTPS

    ufw --force enable # Включить UFW без запроса подтверждения
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
    if ufw status | grep -q "Status: inactive"; then
        echo -e "${RED}UFW выключен!${NC}"
    else
        ufw status verbose
    fi
}

# Функция добавления правила
add_rule() {
    echo "Введите порт (или сервис, например, ssh, http, https):"
    read -r port
    ufw allow "$port/tcp"
    echo -e "${GREEN}Разрешен доступ к $port${NC}"
}

# Функция удаления правила
delete_rule() {
    echo "Введите порт (или сервис), который нужно удалить:"
    read -r port
    ufw delete allow "$port/tcp"
    echo -e "${RED}Удалено правило для $port${NC}"
}

# Функция блокировки порта
block_rule() {
    echo "Введите порт (или сервис), который нужно заблокировать:"
    read -r port
    ufw deny "$port/tcp"
    echo -e "${RED}Заблокирован доступ к $port${NC}"
}

# Функция удаления скрипта
remove_script() {
    local SCRIPT_PATH
    SCRIPT_PATH=$(realpath "$0")
    if [[ -f "$SCRIPT_PATH" ]]; then
        rm "$SCRIPT_PATH"
        echo -e "${GREEN}Скрипт успешно удален!${NC}"
        exit 0
    else
        echo -e "${RED}Скрипт не найден!${NC}"
    fi
}

# Функция установки Fail2Ban
install_fail2ban() {
    if ! command -v fail2ban-client &> /dev/null; then
        echo -e "${RED}Fail2Ban не установлен! Устанавливаю...${NC}"
        apt update && apt install -y fail2ban
        systemctl enable --now fail2ban  # Добавление Fail2Ban в автозапуск
        echo -e "${GREEN}Fail2Ban установлен и запущен! Добавлен в автозапуск!${NC}"
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

# Функция управления UFW
ufw_menu() {
    while true; do
        tput clear
        echo -e "${GREEN}Меню управления UFW:${NC}"
        echo "1) Включить UFW (22,80,443 открыты по умолчанию)"
        echo "2) Отключить UFW"
        echo "3) Сбросить настройки UFW"
        echo "4) Показать статус UFW"
        echo "5) Удалить скрипт, отключить фаервол и удалить Fail2Ban"
        echo "0) Назад"
        echo "Выберите действие: "
        read -r ufw_option

        case $ufw_option in
            1) enable_ufw ;;
            2) disable_ufw ;;
            3) reset_ufw ;;
            4) show_status ;;
            5)
                remove_script
                disable_ufw
                remove_fail2ban
                exit 0
                ;;
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
    echo "5) Fail2Ban"
    echo "0) Выйти"
    echo "Выберите действие: "
    read -r option

    case $option in
        1) ufw_menu ;;
        2) add_rule ;;
        3) delete_rule ;;
        4) block_rule ;;
        5)
            while true; do
                tput clear
                echo -e "${GREEN}Меню Fail2Ban:${NC}"
                echo "1) Установить Fail2Ban"
                echo "2) Показать статус заблокированных IP для SSH"
                echo "3) Показать отчёт Fail2Ban"
                echo "4) Удалить Fail2Ban"
                echo "0) Назад"
                echo "Выберите действие: "
                read -r fail2ban_option

                case $fail2ban_option in
                    1) install_fail2ban ;;
                    2)
                        if command -v fail2ban-client &> /dev/null; then
                            fail2ban-client status sshd
                        else
                            echo -e "${RED}Fail2Ban не установлен!${NC}"
                        fi
                        ;;
                    3) show_fail2ban_report ;;
                    4) remove_fail2ban ;;
                    0) break ;;
                    *) echo -e "${RED}Неверный ввод!${NC}" ;;
                esac

                echo "Нажмите Enter для продолжения..."
                read -r
            done
            ;;
        0) break ;;  # Завершает цикл и выходит из скрипта
        *) echo -e "${RED}Неверный ввод!${NC}" ;;
    esac

    echo "Нажмите Enter для продолжения..."
    read -r
done