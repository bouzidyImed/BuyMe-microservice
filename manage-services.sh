#!/bin/bash

# === CONFIGURATION ===
KAFKA_DIR=~/kafka_2.13-3.8.0
PROJECT_DIR=~/Documents/e-commerce-ms
LOG_DIR=$PROJECT_DIR/logs
mkdir -p "$LOG_DIR"

# === COLORS ===
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m'

# === SERVICES ===
SPRING_SERVICES=(
  eureka-server
  api-gateway
  auth-register-service
  catalogue-service
  cart-service
  kafka-service
  order-service
  payment-service
)
ANGULAR_SERVICES=(
  BuyMeFront
)
SYSTEM_SERVICES=(
  kafka
  zookeeper
  xampp
)

# === FUNCTIONS ===
show_manual() {
    echo -e "${BLUE}================ E-COMMERCE MICROSERVICES MANAGER ================${NC}"
    echo -e "A Bash script to manage microservices for an e-commerce application."
    echo -e "Controls Spring Boot services, Angular frontend, Kafka, ZooKeeper, and XAMPP.\n"

    echo -e "${BLUE}=== FEATURES ===${NC}"
    echo -e "1. Start/Stop/Restart services individually or all at once."
    echo -e "2. Monitor service status with process IDs."
    echo -e "3. Watch Spring Boot and Angular services for code changes and auto-restart."
    echo -e "4. Interactive menu for easy management."
    echo -e "5. Log management with output saved to $LOG_DIR."
    echo -e "6. Color-coded terminal output for clarity.\n"

    echo -e "${BLUE}=== COMMANDS ===${NC}"
    echo -e "${GREEN}start <service|all>${NC}    : Start a specific service or all services."
    echo -e "                     Example: ./manage-services.sh start BuyMeFront"
    echo -e "${GREEN}stop <service|all>${NC}     : Stop a specific service or all services."
    echo -e "                     Example: ./manage-services.sh stop kafka"
    echo -e "${GREEN}restart <service|all>${NC}  : Restart a specific service or all services."
    echo -e "                     Example: ./manage-services.sh restart all"
    echo -e "${GREEN}status${NC}                 : Show running status of all services with PIDs."
    echo -e "                     Example: ./manage-services.sh status"
    echo -e "${GREEN}watch <service>${NC}        : Monitor a Spring or Angular service for code changes and auto-restart."
    echo -e "                     Example: ./manage-services.sh watch BuyMeFront"
    echo -e "${GREEN}menu${NC}                   : Open an interactive menu for service management."
    echo -e "                     Example: ./manage-services.sh menu"
    echo -e "${GREEN}help${NC}                   : Display this help manual."
    echo -e "                     Example: ./manage-services.sh help\n"

    echo -e "${GREEN}payment-start${NC}         : Start the payment service (shorthand)."
    echo -e "                     Example: ./manage-services.sh payment-start"
    echo -e "${GREEN}payment-stop${NC}          : Stop the payment service (shorthand)."
    echo -e "                     Example: ./manage-services.sh payment-stop"
    echo -e "${GREEN}payment-restart${NC}       : Restart the payment service (shorthand)."
    echo -e "                     Example: ./manage-services.sh payment-restart"

    echo -e "${BLUE}=== SUPPORTED SERVICES ===${NC}"
    echo -e "${YELLOW}Spring Boot Services:${NC}"
    for s in "${SPRING_SERVICES[@]}"; do
        echo -e "  - $s"
    done
    echo -e "${YELLOW}Angular Services:${NC}"
    for s in "${ANGULAR_SERVICES[@]}"; do
        echo -e "  - $s"
    done
    echo -e "${YELLOW}System Services:${NC}"
    for s in "${SYSTEM_SERVICES[@]}"; do
        echo -e "  - $s"
    done
    echo -e "\n${BLUE}=== USAGE NOTES ===${NC}"
    echo -e "- Logs are saved in $LOG_DIR/<service>.log."
    echo -e "- Ensure Kafka is installed at $KAFKA_DIR."
    echo -e "- XAMPP requires sudo privileges; ensure proper permissions."
    echo -e "- The 'watch' command requires 'inotify-tools' (install via 'sudo apt install inotify-tools')."
    echo -e "- Use exact service names as listed above."
    echo -e "- Press Ctrl+C to exit watch mode or the interactive menu."
    echo -e "${BLUE}============================================================${NC}"
}

get_pid() {
    local SVC=$1
    if [[ " ${ANGULAR_SERVICES[*]} " =~ " $SVC " ]]; then
        pgrep -f "node.*ng serve.*$SVC" | grep -v "grep"
    else
        pgrep -f ".*$SVC.*" | grep -v "grep"
    fi
}

start_service() {
    local SVC=$1
    local LOG_FILE="$LOG_DIR/$SVC.log"
    if [ "$SVC" == "all" ]; then
        for s in "${SPRING_SERVICES[@]}" "${ANGULAR_SERVICES[@]}" "${SYSTEM_SERVICES[@]}"; do
            start_service "$s"
        done
        return
    fi
    if [ -n "$(get_pid "$SVC")" ]; then
        echo -e "${YELLOW}⚙️ $SVC already running${NC}"
        return
    fi
    if [[ " ${SPRING_SERVICES[*]} " =~ " $SVC " ]]; then
        echo -e "${BLUE}▶ Starting $SVC...${NC}"
        cd "$PROJECT_DIR/$SVC" || { echo -e "${RED}❌ Failed to change to $PROJECT_DIR/$SVC${NC}"; return; }
        : > "$LOG_FILE"
        nohup mvn spring-boot:run -Dspring-boot.run.profiles=local > "$LOG_FILE" 2>&1 &
        sleep 5
        if [ -n "$(get_pid "$SVC")" ]; then
            echo -e "${GREEN}✅ $SVC started (PID: $(get_pid "$SVC"))${NC}"
        else
            echo -e "${RED}❌ Failed to start $SVC. Check $LOG_FILE for details.${NC}"
        fi
    elif [[ " ${ANGULAR_SERVICES[*]} " =~ " $SVC " ]]; then
        echo -e "${BLUE}▶ Starting $SVC...${NC}"
        cd "$PROJECT_DIR/$SVC" || { echo -e "${RED}❌ Failed to change to $PROJECT_DIR/$SVC${NC}"; return; }
        : > "$LOG_FILE"
        nohup ng serve -o > "$LOG_FILE" 2>&1 &
        sleep 5
        if [ -n "$(get_pid "$SVC")" ]; then
            echo -e "${GREEN}✅ $SVC started (PID: $(get_pid "$SVC"))${NC}"
        else
            echo -e "${RED}❌ Failed to start $SVC. Check $LOG_FILE for details.${NC}"
        fi
    elif [ "$SVC" == "kafka" ]; then
        cd "$KAFKA_DIR" || { echo -e "${RED}❌ Failed to change to $KAFKA_DIR${NC}"; return; }
        : > "$LOG_DIR/kafka.log"
        nohup bin/kafka-server-start.sh config/server.properties > "$LOG_DIR/kafka.log" 2>&1 &
        sleep 5
        echo -e "${GREEN}✅ Kafka started${NC}"
    elif [ "$SVC" == "zookeeper" ]; then
        cd "$KAFKA_DIR" || { echo -e "${RED}❌ Failed to change to $KAFKA_DIR${NC}"; return; }
        : > "$LOG_DIR/zookeeper.log"
        nohup bin/zookeeper-server-start.sh config/zookeeper.properties > "$LOG_DIR/zookeeper.log" 2>&1 &
        sleep 5
        echo -e "${GREEN}✅ ZooKeeper started${NC}"
    elif [ "$SVC" == "xampp" ]; then
        : > "$LOG_DIR/xampp.log"
        sudo /opt/lampp/xampp start > "$LOG_DIR/xampp.log" 2>&1
        echo -e "${GREEN}✅ XAMPP started${NC}"
    else
        echo -e "${RED}❌ Unknown service: $SVC${NC}"
    fi
}

stop_service() {
    local SVC=$1
    if [ "$SVC" == "all" ]; then
        echo -e "${BLUE}▶ Stopping all services...${NC}"
        for s in "${SPRING_SERVICES[@]}" "${ANGULAR_SERVICES[@]}" "${SYSTEM_SERVICES[@]}"; do
            local PIDS=$(get_pid "$s")
            if [ -n "$PIDS" ]; then
                echo -e "${YELLOW}▶ Stopping $s (PID: $PIDS)...${NC}"
                for PID in $PIDS; do
                    kill -2 "$PID" 2>/dev/null
                    sleep 3
                    if ps -p "$PID" > /dev/null 2>&1; then
                        kill -9 "$PID" 2>/dev/null
                    fi
                done
                echo -e "${GREEN}✅ $s stopped${NC}"
            else
                if [ "$s" == "kafka" ]; then
                    cd "$KAFKA_DIR" 2>/dev/null && bin/kafka-server-stop.sh > /dev/null 2>&1
                    sleep 2
                    echo -e "${GREEN}✅ Kafka stopped${NC}"
                elif [ "$s" == "zookeeper" ]; then
                    cd "$KAFKA_DIR" 2>/dev/null && bin/zookeeper-server-stop.sh > /dev/null 2>&1
                    sleep 2
                    echo -e "${GREEN}✅ ZooKeeper stopped${NC}"
                elif [ "$s" == "xampp" ]; then
                    sudo /opt/lampp/xampp stop > "$LOG_DIR/xampp.log" 2>&1
                    echo -e "${GREEN}✅ XAMPP stopped${NC}"
                elif [[ " ${ANGULAR_SERVICES[*]} " =~ " $s " ]]; then
                    pkill -f "node.*ng serve.*$s" 2>/dev/null
                    sleep 2
                    echo -e "${GREEN}✅ $s stopped${NC}"
                else
                    echo -e "${YELLOW}⚙️ $s not running${NC}"
                fi
            fi
        done
        return
    fi
    local PIDS=$(get_pid "$SVC")
    if [ -n "$PIDS" ]; then
        echo -e "${YELLOW}▶ Stopping $SVC (PID: $PIDS)...${NC}"
        for PID in $PIDS; do
            kill -2 "$PID" 2>/dev/null
            sleep 3
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -9 "$PID" 2>/dev/null
            fi
        done
        echo -e "${GREEN}✅ $SVC stopped${NC}"
    else
        if [ "$SVC" == "kafka" ]; then
            cd "$KAFKA_DIR" 2>/dev/null && bin/kafka-server-stop.sh > /dev/null 2>&1
            sleep 2
            echo -e "${GREEN}✅ Kafka stopped${NC}"
        elif [ "$SVC" == "zookeeper" ]; then
            cd "$KAFKA_DIR" 2>/dev/null && bin/zookeeper-server-stop.sh > /dev/null 2>&1
            sleep 2
            echo -e "${GREEN}✅ ZooKeeper stopped${NC}"
        elif [ "$SVC" == "xampp" ]; then
            sudo /opt/lampp/xampp stop > "$LOG_DIR/xampp.log" 2>&1
            echo -e "${GREEN}✅ XAMPP stopped${NC}"
        elif [[ " ${ANGULAR_SERVICES[*]} " =~ " $SVC " ]]; then
            pkill -f "node.*ng serve.*$SVC" 2>/dev/null
            sleep 2
            echo -e "${GREEN}✅ $SVC stopped${NC}"
        else
            echo -e "${YELLOW}⚙️ $SVC not running${NC}"
        fi
    fi
}

restart_service() {
    local SVC=$1
    if [ "$SVC" == "all" ]; then
        stop_service "all"
        sleep 2
        start_service "all"
        return
    fi
    stop_service "$SVC"
    sleep 2
    start_service "$SVC"
}

show_status() {
    echo -e "${BLUE}📊 Current Status:${NC}"
    for s in "${SPRING_SERVICES[@]}" "${ANGULAR_SERVICES[@]}" "${SYSTEM_SERVICES[@]}"; do
        local PIDS=$(get_pid "$s")
        if [ -n "$PIDS" ]; then
            echo -e "${GREEN}🟢 $s (PID: $PIDS)${NC}"
        else
            echo -e "${RED}🔴 $s stopped${NC}"
        fi
    done
}

watch_service() {
    local SVC=$1
    if [[ ! " ${SPRING_SERVICES[*]} ${ANGULAR_SERVICES[*]} " =~ " $SVC " ]]; then
        echo -e "${RED}❌ Only Spring and Angular services can be watched${NC}"
        return
    fi
    echo -e "${BLUE}👀 Watching $SVC for changes... Ctrl+C to stop.${NC}"
    if [[ " ${SPRING_SERVICES[*]} " =~ " $SVC " ]]; then
        WATCH_DIR="$PROJECT_DIR/$SVC/src"
    elif [[ " ${ANGULAR_SERVICES[*]} " =~ " $SVC " ]]; then
        WATCH_DIR="$PROJECT_DIR/$SVC"
    fi
    while true; do
        inotifywait -q -r -e modify,create,delete "$WATCH_DIR" --exclude '/\.' 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${YELLOW}🔄 Change detected, restarting $SVC...${NC}"
            restart_service "$SVC"
        fi
    done
}

interactive_menu() {
    while true; do
        echo -e "\n${BLUE}===== Interactive Menu =====${NC}"
        echo "1) Start a service"
        echo "2) Stop a service"
        echo "3) Restart a service"
        echo "4) Show status"
        echo "5) Watch a service for code changes"
        echo "6) Show manual"
        echo "0) Exit"
        read -p "Choose an option: " opt
        case $opt in
            1) read -p "Enter service name or 'all': " svc; start_service "$svc";;
            2) read -p "Enter service name or 'all': " svc; stop_service "$svc";;
            3) read -p "Enter service name or 'all': " svc; restart_service "$svc";;
            4) show_status;;
            5) read -p "Enter Spring or Angular service name: " svc; watch_service "$svc";;
            6) show_manual;;
            0) exit 0;;
            *) echo "Invalid option";;
        esac
    done
}

# === MAIN CLI HANDLER ===
CMD=$1
ARG=$2
case $CMD in
    start) start_service "$ARG";;
    stop) stop_service "$ARG";;
    restart) restart_service "$ARG";;
    payment-start) start_service "payment-service";;
    payment-stop) stop_service "payment-service";;
    payment-restart) restart_service "payment-service";;
    status) show_status;;
    watch) watch_service "$ARG";;
    menu) interactive_menu;;
    help|--help) show_manual;;
    *) show_manual;;
esac